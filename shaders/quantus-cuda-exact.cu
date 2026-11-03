// NVRTC 12.8: --gpu-architecture=compute_120 (o compute_52) --std=c++17 -DSPARSE_KIND=2 -Ishaders
// TokenMiner Q1: exact canonical Goldilocks arithmetic, one nonce per thread.
// Parameter provenance: qp-poseidon-core (MIT), THIRD_PARTY_NOTICES.md.
typedef unsigned long long u64;
typedef unsigned int u32;
static const u64 P = 0xffffffff00000001ULL;
static const u64 EPS = 0xffffffffULL;
#include "quantus-cuda-constants.cuh"

__device__ __forceinline__ u64 canon(u64 x) { return x >= P ? x-P : x; }
__device__ __forceinline__ u64 add(u64 a, u64 b) {
    a=canon(a); b=canon(b);
    u64 s=a+b;
    // Canonical a+b <= 2p-2. With carry, s <= 2^64-2*EPS-2,
    // hence adding EPS cannot itself overflow. Canonicalize once afterwards.
    if(s<a) s+=EPS;
    return canon(s);
}
__device__ __forceinline__ u64 reduce128(u64 lo, u64 hi) {
    // 2^64 = EPS and 2^96 = -1 (mod p): lo - hi_hi + hi_lo*EPS.
    u64 h=hi>>32, t=lo-h;
    // Borrow's wrap introduced 2^64, so subtract EPS. If borrowed,
    // t >= 2^64-(2^32-1), and this correction cannot borrow again.
    if(lo<h) t-=EPS;
    return add(t,(hi & EPS)*EPS);
}
__device__ __forceinline__ u64 mul(u64 a,u64 b) {
    return reduce128(a*b,__umul64hi(a,b));
}
__device__ __forceinline__ u64 pow7(u64 x) {
    u64 x2=mul(x,x),x3=mul(x2,x),x4=mul(x2,x2);
    return mul(x4,x3);
}
__device__ __forceinline__ void external(u64 s[12]) {
    #pragma unroll
    for(int j=0;j<12;j+=4) {
        u64 a=s[j],b=s[j+1],c=s[j+2],d=s[j+3];
        u64 total=add(add(a,b),add(c,d));
        s[j]=add(add(total,a),add(b,b));
        s[j+1]=add(add(total,b),add(c,c));
        s[j+2]=add(add(total,c),add(d,d));
        s[j+3]=add(add(total,d),add(a,a));
    }
    #pragma unroll
    for(int i=0;i<4;i++) {
        u64 sum=add(add(s[i],s[i+4]),s[i+8]);
        s[i]=add(s[i],sum); s[i+4]=add(s[i+4],sum); s[i+8]=add(s[i+8],sum);
    }
}
__device__ __forceinline__ void full(u64 s[12],const u64* rc,int round) {
    #pragma unroll
    for(int i=0;i<12;i++) s[i]=pow7(add(s[i],rc[round*12+i]));
    external(s);
}
__device__ __forceinline__ void finish(u64 s[12]) {
    #pragma unroll 1
    for(int r=1;r<4;r++) full(s,RC_INITIAL,r);
    #pragma unroll 1
    for(int r=0;r<22;r++) {
        s[0]=pow7(add(s[0],RC_INTERNAL[r]));
        u64 sum=0;
        #pragma unroll
        for(int i=0;i<12;i++) sum=add(sum,s[i]);
        #pragma unroll
        for(int i=0;i<12;i++) s[i]=add(mul(s[i],DIAG[i]),sum);
    }
    #pragma unroll 1
    for(int r=0;r<4;r++) full(s,RC_TERMINAL,r);
}
__device__ __forceinline__ void permute(u64 s[12]) {
    external(s); full(s,RC_INITIAL,0); finish(s);
}
__device__ __forceinline__ u32 swap32(u32 x) { return __byte_perm(x,0,0x0123); }
__device__ __forceinline__ u64 swap64(u64 x) {
    return ((u64)swap32((u32)x)<<32)|swap32((u32)(x>>32));
}
__device__ __forceinline__ void prefix(const u64* pre,u64 nonce,u64 s[12]) {
    u64 contribution[12]={0};
    contribution[6]=swap32((u32)(nonce>>32));
    contribution[7]=swap32((u32)nonce);
    external(contribution);
    #pragma unroll
    for(int i=0;i<12;i++) s[i]=pow7(add(pre[i],contribution[i]));
    external(s); finish(s);
    s[0]=add(s[0],1); s[1]=add(s[1],1);
    permute(s);
}
__device__ __forceinline__ bool prefix_le(const u64 s[12],const u64* target) {
    #pragma unroll
    for(int i=0;i<4;i++) {
        u64 x=swap64(s[i]);
        if(x<target[i]) return true;
        if(x>target[i]) return false;
    }
    return true; // Equal upper256 must be checked with the full512 CPU hash.
}
extern "C" __global__ void quantus_mine(const u64* pre,const u64* target,
    u64 counter,u32 count,u32 capacity,u32* result) {
    u32 i=blockIdx.x*blockDim.x+threadIdx.x;
    if(i>=count) return;
    u64 s[12]; prefix(pre,counter+i,s);
    if(prefix_le(s,target)) {
        u32 position=atomicAdd(result,1U);
        if(position<capacity) result[position+1]=i;
    }
}
extern "C" __global__ void quantus_hashes(const u64* pre,u64 counter,u32 count,u64* output) {
    u32 i=blockIdx.x*blockDim.x+threadIdx.x;
    if(i>=count) return;
    u64 s[12]; prefix(pre,counter+i,s);
    #pragma unroll
    for(int w=0;w<4;w++) output[32+w*count+i]=s[w];
    permute(s);
    #pragma unroll
    for(int w=0;w<4;w++) output[32+(w+4)*count+i]=s[w];
}
extern "C" __global__ void quantus_arithmetic(const u64* pairs,u32 count,u64* output) {
    u32 i=blockIdx.x*blockDim.x+threadIdx.x;
    if(i>=count) return;
    u64 a=pairs[2*i],b=pairs[2*i+1];
    output[32+5*i]=add(a,b); output[32+5*i+1]=mul(a,b);
    output[32+5*i+2]=mul(a,a); output[32+5*i+3]=pow7(a);
    output[32+5*i+4]=reduce128(a,b);
}

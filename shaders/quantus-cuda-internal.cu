// NVRTC 12.8: --gpu-architecture=compute_120 (o compute_52) --std=c++17 -DSPARSE_KIND=2 -DQUANTUS_VARIANT=2 -Ishaders
// TokenMiner Q2: independent exact lazy/wide/square experiments, same Q1 hash.
#ifndef QUANTUS_VARIANT
#define QUANTUS_VARIANT 1
#endif
// 1 lazy; 2 lazy+wide internal; 3 adds wide external;
// 4 lazy+wide internal+square; 5 lazy+square (no wide layers).
// Parameter provenance: qp-poseidon-core (MIT), THIRD_PARTY_NOTICES.md.
typedef unsigned long long u64;
typedef unsigned int u32;
static const u64 P = 0xffffffff00000001ULL;
static const u64 EPS = 0xffffffffULL;
#include "quantus-cuda-constants.cuh"

__device__ __forceinline__ u64 canon(u64 x) { return x >= P ? x-P : x; }
__device__ __forceinline__ u64 add(u64 a,u64 b) {
    // All u64 representatives accepted. At most two folds; the second fold
    // leaves a value below EPS, so its EPS correction cannot overflow again.
    u64 sum=a+b;
    if(sum<a) {
        u64 previous=sum;
        sum+=EPS;
        if(sum<previous) sum+=EPS;
    }
    return sum;
}
struct Wide { u64 lo; u64 hi; };
__device__ __forceinline__ void accumulate(Wide &w,u64 x) {
    u64 previous=w.lo; w.lo+=x; w.hi+=(w.lo<previous);
}
__device__ __forceinline__ u64 reduce128(u64 lo,u64 hi);
__device__ __forceinline__ u64 square(u64 a) {
    u64 a0=(u32)a,a1=a>>32;
    u64 ll=a0*a0, cross=a0*a1, hh=a1*a1;
    // Middle <= 3*(2^32-1), fits u64. Final hi is the exact high half
    // of a^2, <= 2^64-2; adding the nonnegative terms cannot overflow.
    u64 middle=(ll>>32)+((cross & EPS)<<1);
    u64 lo=(ll & EPS)|(middle<<32);
    u64 hi=hh+((cross>>32)<<1)+(middle>>32);
    return reduce128(lo,hi);
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
    #if QUANTUS_VARIANT >= 4
    u64 x2=square(x),x3=mul(x2,x),x4=square(x2);
#else
    u64 x2=mul(x,x),x3=mul(x2,x),x4=mul(x2,x2);
#endif
    return mul(x4,x3);
}
__device__ __forceinline__ void external(u64 s[12]) {
#if QUANTUS_VARIANT == 3
    // Each block output <= 7*U64_MAX; after three-block sum plus self
    // <= 28*U64_MAX. Wide.hi <= 27, with no 128-bit wrap.
    Wide b[12];
    #pragma unroll
    for(int j=0;j<12;j+=4) {
        Wide total={0,0};
        #pragma unroll
        for(int i=0;i<4;i++) accumulate(total,s[j+i]);
        #pragma unroll
        for(int i=0;i<4;i++) {
            b[j+i]=total;
            accumulate(b[j+i],s[j+i]);
            accumulate(b[j+i],s[j+((i+1)&3)]);
            accumulate(b[j+i],s[j+((i+1)&3)]);
        }
    }
    #pragma unroll
    for(int i=0;i<12;i++) {
        int lane=i&3;
        Wide w=b[i];
        #pragma unroll
        for(int j=lane;j<12;j+=4) {
            accumulate(w,b[j].lo); w.hi+=b[j].hi;
        }
        s[i]=reduce128(w.lo,w.hi);
    }
#else
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
#endif
}
__device__ __forceinline__ void internal_linear(u64 s[12]) {
#if QUANTUS_VARIANT >= 2 && QUANTUS_VARIANT <= 4
    Wide sum={0,0};
    #pragma unroll
    for(int i=0;i<12;i++) accumulate(sum,s[i]);
    #pragma unroll
    for(int i=0;i<12;i++) {
        u64 lo=s[i]*DIAG[i],hi=__umul64hi(s[i],DIAG[i]);
        u64 previous=lo; lo+=sum.lo; hi+=sum.hi+(lo<previous);
        // All Quantus DIAG <= U64_MAX-12, so x*DIAG+sum <= U64_MAX^2.
        // Preserve product+sum in 128 bits, then reduce once, with all carries.
        s[i]=reduce128(lo,hi);
    }
#else
    u64 sum=0;
    #pragma unroll
    for(int i=0;i<12;i++) sum=add(sum,s[i]);
    #pragma unroll
    for(int i=0;i<12;i++) s[i]=add(mul(s[i],DIAG[i]),sum);
#endif
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
        internal_linear(s);
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
        u64 x=swap64(canon(s[i]));
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
    for(int w=0;w<4;w++) output[32+w*count+i]=canon(s[w]);
    permute(s);
    #pragma unroll
    for(int w=0;w<4;w++) output[32+(w+4)*count+i]=canon(s[w]);
}
extern "C" __global__ void quantus_arithmetic(const u64* pairs,u32 count,u64* output) {
    u32 i=blockIdx.x*blockDim.x+threadIdx.x;
    if(i>=count) return;
    u64 a=pairs[2*i],b=pairs[2*i+1];
    output[32+5*i]=canon(add(a,b)); output[32+5*i+1]=canon(mul(a,b));
#if QUANTUS_VARIANT >= 4
    output[32+5*i+2]=canon(square(a));
#else
    output[32+5*i+2]=canon(mul(a,a));
#endif
    output[32+5*i+3]=canon(pow7(a));
    output[32+5*i+4]=canon(reduce128(a,b));
}

extern "C" __global__ void quantus_layers(const u64* input,u32 count,u64* output) {
    u32 i=blockIdx.x*blockDim.x+threadIdx.x;
    if(i>=count) return;
    u64 a[12],b[12];
    #pragma unroll
    for(int j=0;j<12;j++) a[j]=b[j]=input[12*i+j];
    external(a); internal_linear(b);
    #pragma unroll
    for(int j=0;j<12;j++) {
        output[32+24*i+j]=canon(a[j]);
        output[32+24*i+12+j]=canon(b[j]);
    }
}

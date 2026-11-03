// NVRTC 12.8: --gpu-architecture=compute_120 --std=c++17 -DSPARSE_KIND=2 (con --gpu-architecture=compute_52 da el PTX generico)
// Q3 own kernels. Q2 arithmetic is frozen and reused with variant internal.
#define QUANTUS_VARIANT 2
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
// Constantes de qp-poseidon-core 3.1.0 (MIT), ver licenses/qp-poseidon-core-MIT.txt
__device__ __constant__ u64 RC_INITIAL[48] = {
  0xc002e770975b1607ULL,
  0xbca51a8dfe14593aULL,
  0x72938dfbe774f7f9ULL,
  0xe4f2fe29e03234acULL,
  0xd5e0ba2f541b6449ULL,
  0xec33b868f3cc46c1ULL,
  0x486dcb55419d475aULL,
  0x6c1cb2a358cc24f1ULL,
  0xe3f30d509a1436bbULL,
  0xd9a64f068dca7c29ULL,
  0xe59b3f57aabba1aeULL,
  0x2a3dd4505b478fdcULL,
  0xada1f8dc7676ed25ULL,
  0x2711aa8b5509d516ULL,
  0x4ae6acd0c9c92897ULL,
  0x56eb3d6b5256d67aULL,
  0x1f7a9d55923bf51eULL,
  0x3600427d397a7f68ULL,
  0xe5076df75b72c3d0ULL,
  0xfcd59aa12c6090adULL,
  0xcd895e8c68b57a9eULL,
  0x41df7ef9d730ae3eULL,
  0xee3e2b889abe977dULL,
  0xd29bb7edbeb9c405ULL,
  0x7d5c08eef608e382ULL,
  0x89ae889caaf0802cULL,
  0xb35a8e976d2af617ULL,
  0xdb14234eafaf5173ULL,
  0x78f04462d48b1c98ULL,
  0x265293b0e47ce88aULL,
  0x999a649b69b9d32fULL,
  0x64b0a186698e01d3ULL,
  0xee0b22d0dfae8bb8ULL,
  0x4fd53e50ca04a7eeULL,
  0x5762bfe181f25047ULL,
  0xf51593e2beb5e3bdULL,
  0x1e5e2b5760e32477ULL,
  0x622462a1f9aaaeedULL,
  0xaa284b3ecdb222aeULL,
  0x63c8e72f542bf3fcULL,
  0x3ba588cacb43b5e0ULL,
  0x23eda6f3c99150ddULL,
  0xaad3bea4baac9a5aULL,
  0xe9da8d699b94184aULL,
  0xcdb13f4cd93e024cULL,
  0x902cbd0956f655e3ULL,
  0x5b4e40ffc759532fULL,
  0xde795c20a2357af7ULL
};
__device__ __constant__ u64 RC_INTERNAL[22] = {
  0x97f7798a784ad863ULL,
  0xd1d2bf082f60d4f0ULL,
  0x69a377a79f9ad206ULL,
  0xa9d06906a3858e24ULL,
  0x295275001eede5b5ULL,
  0x5874e441117bd746ULL,
  0x8a084bbba8ed86ccULL,
  0x3defd7645cde6425ULL,
  0x3998cfe6871cc137ULL,
  0x3e52ef8bca48314aULL,
  0x964a209f85dc9eccULL,
  0x3fcc9ee82cc4577eULL,
  0x8e79b4a5d0096d6dULL,
  0x8492362ad2392556ULL,
  0xee72f470262574d6ULL,
  0x1e0e18496da2444aULL,
  0x0f3a74bf215eaac6ULL,
  0x1b061b76a1c0ded3ULL,
  0x192c42d86803d7a6ULL,
  0xf6d49ff997ae0260ULL,
  0x3ec372e7a0fa3786ULL,
  0x5538cdf4f23445d3ULL
};
__device__ __constant__ u64 RC_TERMINAL[48] = {
  0x7b72c539e0ea4c6eULL,
  0x144573dae2ce9976ULL,
  0x802028b68f35fc88ULL,
  0x6d36c5022c4fe7c2ULL,
  0xa205d0ffa9b9def3ULL,
  0xf6e7e38b1ea6ba2fULL,
  0x34f7909ae5258d64ULL,
  0xb0464d9d77b97fcaULL,
  0x64ddb9d5de7e00a6ULL,
  0x0ed0d75c27975d97ULL,
  0x1cbb36f11127338bULL,
  0x6673e505cfd0b6baULL,
  0x605f902830872e01ULL,
  0x3fd5eb927e95fe4fULL,
  0xe81025b5a24c69cdULL,
  0xf7d0ce75de23f74eULL,
  0xf39942b6a8585089ULL,
  0x6d808a08f7b71df6ULL,
  0xf8806b6588f49a8bULL,
  0x57df2d8c2a32107aULL,
  0x16e7c2074d654a2dULL,
  0x213de241fcf33835ULL,
  0xb0f2b8905a0976f6ULL,
  0xd8e3cf2bbd355417ULL,
  0xe498691679d9330fULL,
  0x763b45d2a3821b28ULL,
  0x0908bf65eb0a1f0dULL,
  0x7691eb2d194b24f4ULL,
  0x0e43551233ae13b2ULL,
  0x93c393dbfc2fe76fULL,
  0x98f607485d48cdeaULL,
  0xe3d95f30309819c0ULL,
  0x1ef581a93eaf6acfULL,
  0x0b24c1b7a030fca4ULL,
  0x624370be5670b327ULL,
  0x5f1e28615a11e486ULL,
  0xfe04051f909e042bULL,
  0x7257e5b147fd3803ULL,
  0xe6ae134bb82f2e78ULL,
  0x5711fd5cf4784511ULL,
  0xf83a42660c08c0bcULL,
  0x2cd8c96d9a3ce855ULL,
  0x7d2ffb1bb0e17271ULL,
  0x85ae1528caea3811ULL,
  0x52a345d5c7adb0b8ULL,
  0x504c4c51f3faee94ULL,
  0xbce34a649cfccaf9ULL,
  0xe0a3389266fb6dc9ULL
};
__device__ __constant__ u64 DIAG[12] = {
  0xc3b6c08e23ba9300ULL,
  0xd84b5de94a324fb6ULL,
  0x0d0c371c5b35b84fULL,
  0x7964f570e7188037ULL,
  0x5daf18bbd996604bULL,
  0x6743bc47b9595257ULL,
  0x5528b9362c59bb70ULL,
  0xac45e25b7127b68bULL,
  0xa2077d7dfbb606b5ULL,
  0xf3faac6faee378aeULL,
  0x0c6388b51545e883ULL,
  0xd27dbb6944917b60ULL
};


__device__ __forceinline__ u64 canon(u64 x) { return x >= P ? x-P : x; }
// Q4 independent exact carry-chain experiment. No miner source copied.
// p = 2^64 - 2^32 + 1; every 64-bit carry must fold by EPS.
// NVIDIA PTX add.cc/addc semantics: a straight-line block preserves CC.CF.
__device__ __forceinline__ u64 add(u64 a,u64 b) {
    u32 lo,hi;
    asm("{\n\t"
        ".reg .u32 x0,x1,c,t;\n\t"
        "add.cc.u32 x0,%2,%4;\n\t"
        "addc.cc.u32 x1,%3,%5;\n\t"
        "addc.u32 c,0,0;\n\t"
        "sub.u32 t,0,c;\n\t" // 0 or 2^32-1 = carry * EPS
        "add.cc.u32 x0,x0,t;\n\t"
        "addc.cc.u32 x1,x1,0;\n\t"
        "addc.u32 c,0,0;\n\t"
        "sub.u32 t,0,c;\n\t"
        "add.cc.u32 x0,x0,t;\n\t"
        "addc.u32 x1,x1,0;\n\t"
        "mov.u32 %0,x0;\n\t"
        "mov.u32 %1,x1;\n\t"
        "}"
        : "=r"(lo),"=r"(hi)
        : "r"((u32)a),"r"((u32)(a>>32)),"r"((u32)b),"r"((u32)(b>>32)));
    // A second carry leaves < EPS, so the last correction cannot overflow.
    // Outputs are written only after all inputs are consumed: alias-safe.
    return ((u64)hi<<32)|lo;
}

// Q7 independent exact one-fold add. Only call with canonical b<P.
__device__ __forceinline__ u64 add_rc(u64 a,u64 b) {
    u32 lo,hi;
    asm("{\n\t"
        ".reg .u32 x0,x1,c,t;\n\t"
        "add.cc.u32 x0,%2,%4;\n\t"
        "addc.cc.u32 x1,%3,%5;\n\t"
        "addc.u32 c,0,0;\n\t"
        "sub.u32 t,0,c;\n\t" // 0 or 2^32-1 = carry * EPS
        "add.cc.u32 x0,x0,t;\n\t"
        "addc.u32 x1,x1,0;\n\t"
        "mov.u32 %0,x0;\n\t"
        "mov.u32 %1,x1;\n\t"
        "}"
        : "=r"(lo),"=r"(hi)
        : "r"((u32)a),"r"((u32)(a>>32)),"r"((u32)b),"r"((u32)(b>>32)));
    // Precondition b<P: wrapped first sum <= b-1 <= 2^64-EPS-2.
    // Its EPS correction is <= 2^64-2; no second carry is possible.
    // Outputs are written only after all inputs are consumed: alias-safe.
    return ((u64)hi<<32)|lo;
}

struct Wide { u64 lo; u64 hi; };
__device__ __forceinline__ void accumulate(Wide &w,u64 x) {
    u64 previous=w.lo; w.lo+=x; w.hi+=(w.lo<previous);
}
__device__ __forceinline__ u64 reduce128(u64 lo,u64 hi);
// Q9 own exact symmetric square, using the Q2 identity and PTX carry chain.
// Distinct from Q2 C++ square: assemble four 32-bit limbs directly.
__device__ __forceinline__ Wide square128(u64 a) {
    u32 a0=(u32)a,a1=(u32)(a>>32),r0,r1,r2,r3;
    asm("{\n\t"
        ".reg .u64 ll,cross,hh;\n\t"
        ".reg .u32 l0,l1,c0,c1,h0,h1,d0,d1,top;\n\t"
        "mul.wide.u32 ll,%4,%4;\n\t"
        "mul.wide.u32 cross,%4,%5;\n\t"
        "mul.wide.u32 hh,%5,%5;\n\t"
        "mov.b64 {l0,l1},ll;\n\t"
        "mov.b64 {c0,c1},cross;\n\t"
        "mov.b64 {h0,h1},hh;\n\t"
        "shl.b32 d0,c0,1;\n\t"
        "shf.l.clamp.b32 d1,c0,c1,1;\n\t"
        "shr.u32 top,c1,31;\n\t"
        "add.cc.u32 d0,d0,l1;\n\t"
        "addc.cc.u32 d1,d1,h0;\n\t"
        "addc.u32 top,top,h1;\n\t"
        "mov.u32 %0,l0;\n\t"
        "mov.u32 %1,d0;\n\t"
        "mov.u32 %2,d1;\n\t"
        "mov.u32 %3,top;\n\t"
        "}"
        : "=r"(r0),"=r"(r1),"=r"(r2),"=r"(r3)
        : "r"(a0),"r"(a1));
    return {((u64)r1<<32)|r0,((u64)r3<<32)|r2};
}
__device__ __forceinline__ u64 square(u64 a) {
    Wide value=square128(a);return reduce128(value.lo,value.hi);
}
extern "C" __global__ void quantus_square_probe(const u64* input,u32 count,u64* output) {
    u32 i=blockIdx.x*blockDim.x+threadIdx.x;if(i>=count)return;
    Wide a=square128(input[2*i]),b=square128(input[2*i+1]);
    output[32+4*i]=a.lo;output[33+4*i]=a.hi;
    output[34+4*i]=b.lo;output[35+4*i]=b.hi;
}


// Q17 own literal Solinas fold: no multiply by EPS. All128 inputs supported.
__device__ __forceinline__ u64 q17_shift_reduce(u32 w0,u32 w1,u32 w2,u32 w3) {
    // l=w0-w2; b=borrow. s=w2-b cannot underflow: b=1 implies w2>0.
    // l+B*(w1+s)=lo+EPS*w2. Capture its carry, then net the w3 borrow.
    // q in{-1,0,1}; the Q15 exact final correction and bounds still apply.
    u32 lo,hi;
    asm("{.reg .u32 l,h,b,k;"
        "sub.cc.u32 l,%2,%4;subc.u32 b,0,0;"
        "sub.cc.u32 l,l,%5;subc.u32 b,b,0;"
        "add.cc.u32 h,%3,%4;"
        "addc.u32 k,0,0;"
        "addc.u32 h,h,b;"
        "sub.u32 l,l,k;"
        "mov.u32 %0,l;mov.u32 %1,h;}"
        :"=r"(lo),"=r"(hi):"r"(w0),"r"(w1),"r"(w2),"r"(w3));
    return ((u64)hi<<32)|lo;
}
__device__ __forceinline__ u64 q17_shift_positive(u32 w0,u32 w1,u32 w2) {
    // For bounded96 input (w2<=28) carry correction can happen at most once.
    u32 lo,hi;
    asm("{.reg .u32 l,h,b,k;"
        "sub.cc.u32 l,%2,%4;subc.u32 b,0,0;"
        "add.cc.u32 h,%3,%4;"
        "addc.u32 k,0,0;"
        "addc.u32 h,h,b;"
        "sub.u32 l,l,k;"
        "mov.u32 %0,l;mov.u32 %1,h;}"
        :"=r"(lo),"=r"(hi):"r"(w0),"r"(w1),"r"(w2));
    return ((u64)hi<<32)|lo;
}

__device__ __forceinline__ u64 q15_reduce(u32 a,u32 b,u32 c,u32 d){return q17_shift_reduce(a,b,c,d);}
__device__ __forceinline__ u64 reduce128(u64 lo,u64 hi) {
    return q15_reduce((u32)lo,(u32)(lo>>32),(u32)hi,(u32)(hi>>32));
}
// Q11: exact product limbs remain live through reduction and DIAG+wide sum.
struct Limbs128 {u32 x0,x1,x2,x3;};


__device__ __forceinline__ Limbs128 q38_mac(u64 a,u64 b,u64 sumlo,u32 sumtop) {
    // Contract: sum<38U; product+sum<U^2. For arbitrary a,b require sum=0.
    Limbs128 w;
    asm("{.reg .u32 r0,r1,r2,r3;"
        "mad.lo.cc.u32 r0,%4,%6,%8;madc.hi.cc.u32 r1,%4,%6,%9;addc.u32 r2,%10,0;mov.u32 r3,0;"
        "mad.lo.cc.u32 r1,%4,%7,r1;madc.hi.cc.u32 r2,%4,%7,r2;addc.u32 r3,r3,0;"
        "mad.lo.cc.u32 r1,%5,%6,r1;madc.hi.cc.u32 r2,%5,%6,r2;addc.u32 r3,r3,0;"
        "mad.lo.cc.u32 r2,%5,%7,r2;madc.hi.u32 r3,%5,%7,r3;"
        "mov.u32 %0,r0;mov.u32 %1,r1;mov.u32 %2,r2;mov.u32 %3,r3;}"
        :"=r"(w.x0),"=r"(w.x1),"=r"(w.x2),"=r"(w.x3)
        :"r"((u32)a),"r"((u32)(a>>32)),"r"((u32)b),"r"((u32)(b>>32)),"r"((u32)sumlo),"r"((u32)(sumlo>>32)),"r"(sumtop));
    return w;
}
__device__ __forceinline__ Limbs128 product_limbs(u64 a,u64 b) {
 u64 lo,hi;asm("mul.lo.u64 %0,%2,%3;mul.hi.u64 %1,%2,%3;":"=l"(lo),"=l"(hi):"l"(a),"l"(b));
 return {(u32)lo,(u32)(lo>>32),(u32)hi,(u32)(hi>>32)};
}
// Independent standard128 identity: cross65, shifted low add, high add-with-carry.
__device__ __forceinline__ Limbs128 q23_pair(u64 a,u64 b) {
    u64 lo,hi;
    asm("{.reg .u64 p0,p1,p2,p3,cross,sl,sh; .reg .u32 cl,ch,top;"
        "mul.wide.u32 p0,%2,%4;mul.wide.u32 p1,%2,%5;"
        "mul.wide.u32 p2,%3,%4;mul.wide.u32 p3,%3,%5;"
        "add.cc.u64 cross,p1,p2;addc.u32 top,0,0;"
        "mov.b64 {cl,ch},cross;mov.b64 sl,{0,cl};mov.b64 sh,{ch,top};"
        "add.cc.u64 %0,p0,sl;addc.u64 %1,p3,sh;}"
        :"=l"(lo),"=l"(hi):"r"((u32)a),"r"((u32)(a>>32)),"r"((u32)b),"r"((u32)(b>>32)));
    return {(u32)lo,(u32)(lo>>32),(u32)hi,(u32)(hi>>32)};
}
__device__ __forceinline__ Wide q23_pair_square(u64 a) {
    u64 lo,hi;
    asm("{.reg .u64 p0,cross,p3,doubled,sl,sh; .reg .u32 cl,ch,top;"
        "mul.wide.u32 p0,%2,%2;mul.wide.u32 cross,%2,%3;mul.wide.u32 p3,%3,%3;"
        "shl.b64 doubled,cross,1;shr.u64 sh,cross,63;cvt.u32.u64 top,sh;"
        "mov.b64 {cl,ch},doubled;mov.b64 sl,{0,cl};mov.b64 sh,{ch,top};"
        "add.cc.u64 %0,p0,sl;addc.u64 %1,p3,sh;}"
        :"=l"(lo),"=l"(hi):"r"((u32)a),"r"((u32)(a>>32)));
    return {lo,hi};
}
// Same proven Q6 corrections, now consuming product limbs without a Wide wrapper.
__device__ __forceinline__ u64 reduce_limbs(Limbs128 w) {
    return q15_reduce(w.x0,w.x1,w.x2,w.x3);
}
__device__ __forceinline__ u64 diag_sum(u64 a,u64 b,Wide sum) {
    return reduce_limbs(q38_mac(a,b,sum.lo,(u32)sum.hi));
}
__device__ __forceinline__ u64 mul(u64 a,u64 b) {return reduce_limbs(product_limbs(a,b));}
extern "C" __global__ void quantus_product32(const u64* pairs,u32 count,u64* output) {
    u32 i=blockIdx.x*blockDim.x+threadIdx.x;if(i>=count)return;
    Limbs128 w=product_limbs(pairs[2*i],pairs[2*i+1]);
    output[32+2*i]=((u64)w.x1<<32)|w.x0;output[33+2*i]=((u64)w.x3<<32)|w.x2;
}

__device__ __forceinline__ u64 pow7(u64 x) {
    #if 1
    u64 x2=square(x),x3=mul(x2,x),x4=square(x2);
#else
    u64 x2=mul(x,x),x3=mul(x2,x),x4=mul(x2,x2);
#endif
    return mul(x4,x3);
}
// Own exact factorization of the frozen Quantus matrix; arbitrary u64 reps.
__device__ __forceinline__ void q13_m4(u64 &a,u64 &b,u64 &c,u64 &d) {
    u64 ab=add(a,b),cd=add(c,d),t=add(ab,cd),tb=add(t,b),td=add(t,d);
    u64 o0=add(tb,ab),o1=add(tb,add(c,c)),o2=add(td,cd),o3=add(td,add(a,a));
    a=o0;b=o1;c=o2;d=o3;
}
__device__ __forceinline__ void q13_external(u64 s[12]) {
    #pragma unroll
    for(int j=0;j<12;j+=4)q13_m4(s[j],s[j+1],s[j+2],s[j+3]);
    #pragma unroll
    for(int i=0;i<4;i++) {
        u64 sum=add(add(s[i],s[i+4]),s[i+8]);
        s[i]=add(s[i],sum);s[i+4]=add(s[i+4],sum);s[i+8]=add(s[i+8],sum);
    }
}
__device__ __forceinline__ void q13_final4(u64 s[12]) {
    u64 a=s[0],b=s[1],c=s[2],d=s[3];
    u64 e=add(s[4],s[8]),f=add(s[5],s[9]),g=add(s[6],s[10]),h=add(s[7],s[11]);
    q13_m4(a,b,c,d);q13_m4(e,f,g,h);
    s[0]=add(add(a,a),e);s[1]=add(add(b,b),f);s[2]=add(add(c,c),g);s[3]=add(add(d,d),h);
}

__device__ __forceinline__ void external(u64 s[12]) {q13_external(s);}
__device__ __forceinline__ void internal_linear(u64 s[12]) {
#if QUANTUS_VARIANT >= 2 && QUANTUS_VARIANT <= 4
    Wide sum={0,0};
    #pragma unroll
    for(int i=0;i<12;i++) accumulate(sum,s[i]);
    #pragma unroll
    for(int i=0;i<12;i++) {
        s[i]=diag_sum(s[i],DIAG[i],sum);
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
    for(int i=0;i<12;i++) s[i]=pow7(add_rc(s[i],rc[round*12+i]));
    external(s);
}
// Q11 B: anticipatory element0 chain. Exact sum and all DIAG outputs retained.
__device__ __forceinline__ void internal_pipeline(u64 s[12]) {
    u64 x=pow7(add_rc(s[0],RC_INTERNAL[0]));
    #pragma unroll 1
    for(int r=0;r<22;r++) {
        Wide sum={0,0};
        #pragma unroll
        for(int i=1;i<12;i++)accumulate(sum,s[i]);
        accumulate(sum,x);
        u64 next0=diag_sum(x,DIAG[0],sum);
        // This value is independent of the eleven remaining output rows.
        u64 nextx=r<21?pow7(add_rc(next0,RC_INTERNAL[r+1])):next0;
        #pragma unroll
        for(int i=1;i<12;i++)s[i]=diag_sum(s[i],DIAG[i],sum);
        x=nextx;
    }
    s[0]=x;
}

__device__ __forceinline__ void finish(u64 s[12]) {
    #pragma unroll 1
    for(int r=1;r<4;r++) full(s,RC_INITIAL,r);
    internal_pipeline(s);
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
#if 1
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

// Probe the actual specialized add against the preserved general add.
extern "C" __global__ void quantus_add_rc_probe(const u64* pairs,u32 count,u64* output) {
    u32 i=blockIdx.x*blockDim.x+threadIdx.x;
    if(i>=count) return;
    u64 a=pairs[2*i],b=canon(pairs[2*i+1]);
    output[32+2*i]=add_rc(a,b);
    output[32+2*i+1]=add(a,b);
}


extern "C" __device__ __constant__ u64 Q61_PRE[14];
__device__ __forceinline__ void sparse_first(const u64* pre,u64 local,u64 s[12]) {
#if SPARSE_KIND == 0
    // Direct Q2 computation for the exact same structured nonces as the caches.
    u64 group=Q61_PRE[12],b=0x40000000ULL;
    u64 x[12]={b+17*local,b+(group&0x3fffffULL)-11*local,
        b+((group>>22)&0x3fffffULL)+3*local,b+(group>>44)-4*local,
        b-17*local,b+11*local,b-3*local,b+4*local,0,0,0,0};
    external(x);
    #pragma unroll
    for(int i=0;i<12;i++) s[i]=pow7(add(Q61_PRE[i],x[i]));
    external(s);
#elif SPARSE_KIND == 1
    #pragma unroll
    for(int i=0;i<12;i++) s[i]=Q61_PRE[i];
    u64 offset=35*local; // <= 2,210,644,905: no 64-bit wrap.
    s[3]=pow7(add(Q61_PRE[3],offset));
    s[7]=pow7(add(Q61_PRE[7],P-offset));
    external(s);
#else
    u64 offset=35*local;
    u64 x=pow7(add(Q61_PRE[12],offset)),y=pow7(add(Q61_PRE[13],P-offset));
    // M(e3*x+e7*y). Positive small coefficients, using exact lazy sums.
    u64 common=add(x,y),twice=add(common,common),three=add(twice,common);
    u64 qx[4]={x,x,add(add(x,x),x),add(x,x)};
    u64 qy[4]={y,y,add(add(y,y),y),add(y,y)};
    u64 q[4]={common,common,three,twice};
    #pragma unroll
    for(int i=0;i<4;i++) {
        s[i]=add(Q61_PRE[i],add(q[i],qx[i]));
        s[i+4]=add(Q61_PRE[i+4],add(q[i],qy[i]));
        s[i+8]=add(Q61_PRE[i+8],q[i]);
    }
#endif
}
__device__ __forceinline__ void sparse_prefix(const u64* pre,u64 local,u64 s[12]) {
    sparse_first(pre,local,s); finish(s);
    s[0]=add(s[0],1);s[1]=add(s[1],1);permute(s);
}
__device__ __forceinline__ void q13_mining_prefix(const u64* pre,u64 local,u64 s[12]) {
    sparse_first(pre,local,s);finish(s);s[0]=add(s[0],1);s[1]=add(s[1],1);
    external(s);
    #pragma unroll 1
    for(int r=0;r<4;r++)full(s,RC_INITIAL,r);
    internal_pipeline(s);
    #pragma unroll 1
    for(int r=0;r<3;r++)full(s,RC_TERMINAL,r);
    #pragma unroll
    for(int i=0;i<12;i++)s[i]=pow7(add_rc(s[i],RC_TERMINAL[36+i]));
    q13_final4(s);
}
// Exact temporary 96-bit representation. M4 <=7*U64, full output <=28*U64.

struct SmallWide {u32 lo,mid,hi;};
__device__ __forceinline__ SmallWide sw_from64(u64 x){return {(u32)x,(u32)(x>>32),0};}
__device__ __forceinline__ SmallWide sw_add(SmallWide a,SmallWide b) {
    SmallWide w;
    asm("{.reg .u32 x,y,z;\n\t"
        "add.cc.u32 x,%3,%6;addc.cc.u32 y,%4,%7;addc.u32 z,%5,%8;\n\t"
        "mov.u32 %0,x;mov.u32 %1,y;mov.u32 %2,z;}"
        : "=r"(w.lo),"=r"(w.mid),"=r"(w.hi)
        : "r"(a.lo),"r"(a.mid),"r"(a.hi),"r"(b.lo),"r"(b.mid),"r"(b.hi));
    return w;
}

__device__ __forceinline__ void sw_m4(SmallWide& a,SmallWide& b,SmallWide& c,SmallWide& d) {
    SmallWide ab=sw_add(a,b),cd=sw_add(c,d),t=sw_add(ab,cd),tb=sw_add(t,b),td=sw_add(t,d);
    SmallWide x=sw_add(tb,ab),y=sw_add(tb,sw_add(c,c)),z=sw_add(td,cd),w=sw_add(td,sw_add(a,a));
    a=x;b=y;c=z;d=w;
}


__device__ __forceinline__ u64 q14_fold_rc(SmallWide w,u64 rc){w=sw_add(w,sw_from64(rc));return q17_shift_positive(w.lo,w.mid,w.hi);}
__device__ __forceinline__ void q14_mix(u64 s[12],const u64* rc,int base,bool only0) {
    SmallWide b[12];
    #pragma unroll
    for(int i=0;i<12;i++)b[i]=sw_from64(s[i]);
    #pragma unroll
    for(int j=0;j<12;j+=4)sw_m4(b[j],b[j+1],b[j+2],b[j+3]);
    #pragma unroll
    for(int j=0;j<4;j++) {
        SmallWide sum=sw_add(sw_add(b[j],b[j+4]),b[j+8]);
        #pragma unroll
        for(int k=0;k<3;k++) {
            int i=j+4*k;
            u64 bias=rc && (!only0||i==0)?rc[base+(only0?0:i)]:0;
            s[i]=q14_fold_rc(sw_add(sum,b[i]),bias);
        }
    }
}
__device__ __forceinline__ u64 q14_diag_rc(u64 x,u64 d,Wide sum,u64 rc) {
    accumulate(sum,rc);
    return diag_sum(x,d,sum);
}
// Input s0 is biased by INTERNAL[0]; all other rows are ordinary field reps.

__device__ __forceinline__ void q14_internal(u64 s[12]);

// Q16 own coherent phase-stage scheduling, ordinary Q15 arithmetic.
template<int W> __device__ __forceinline__ void q16_base_group(u64 x[W],u64 out[W]) {
    u64 x2[W],x3[W];
    #pragma unroll
    for(int i=0;i<W;i++)x2[i]=square(x[i]);
    #pragma unroll
    for(int i=0;i<W;i++)x3[i]=mul(x2[i],x[i]);
    #pragma unroll
    for(int i=0;i<W;i++)x[i]=square(x2[i]);
    #pragma unroll
    for(int i=0;i<W;i++)out[i]=mul(x[i],x3[i]);
}
__device__ __forceinline__ void q16_group_only(u64 s[12]) {
    #pragma unroll
    for(int j=0;j<12;j+=4) {
        u64 x[4],out[4];
        #pragma unroll
        for(int i=0;i<4;i++)x[i]=s[j+i];
        q16_base_group<4>(x,out);
        #pragma unroll
        for(int i=0;i<4;i++)s[j+i]=out[i];
    }
}
__device__ __forceinline__ void q16_fused_stage(u64 s[12],const u64* rc,int base,bool only0,bool leave) {
    // Consume each group4 into its M4 immediately. Avoid twelve live powers
    // across a separate M4 stage; preserve the exact96bit bounds and RC fold.
    if(leave){q16_group_only(s);return;}
    SmallWide b[12];
    #pragma unroll
    for(int j=0;j<12;j+=4) {
        u64 x[4],out[4];
        #pragma unroll
        for(int i=0;i<4;i++)x[i]=s[j+i];
        q16_base_group<4>(x,out);
        #pragma unroll
        for(int i=0;i<4;i++)b[j+i]=sw_from64(out[i]);
        sw_m4(b[j],b[j+1],b[j+2],b[j+3]);
    }
    #pragma unroll
    for(int j=0;j<4;j++) {
        SmallWide sum=sw_add(sw_add(b[j],b[j+4]),b[j+8]);
        #pragma unroll
        for(int k=0;k<3;k++) {
            int i=j+4*k;
            u64 bias=rc&&(!only0||i==0)?rc[base+(only0?0:i)]:0;
            s[i]=q14_fold_rc(sw_add(sum,b[i]),bias);
        }
    }
}
// Own biased96: before final correction, N = raw64 + q*U modulo P.
// Store top=q+1 (0..2), so residue=N+EPS and every limb is positive.
// M row sum28; precomputed RC-28EPS cancels bias without per-field conversion.
__device__ __forceinline__ SmallWide q23_condensed(Limbs128 w) {
    SmallWide v;
    asm("{.reg .u32 l,h,s,q;"
        "sub.cc.u32 l,%3,%5;subc.u32 s,%5,0;"
        "add.cc.u32 h,%4,s;addc.u32 q,0,0;"
        "sub.cc.u32 l,l,%6;subc.cc.u32 h,h,0;subc.u32 q,q,0;"
        "add.u32 q,q,1;mov.u32 %0,l;mov.u32 %1,h;mov.u32 %2,q;}"
        :"=r"(v.lo),"=r"(v.mid),"=r"(v.hi):"r"(w.x0),"r"(w.x1),"r"(w.x2),"r"(w.x3));
    return v;
}
template<int K> __device__ __forceinline__ u64 q23_m(u64 a,u64 b) {
    return K?reduce_limbs(q23_pair(a,b)):mul(a,b);
}
template<int K> __device__ __forceinline__ u64 q23_s(u64 a) {
    Wide w=K?q23_pair_square(a):square128(a);return reduce128(w.lo,w.hi);
}
template<int K> __device__ __forceinline__ u64 q23_p(u64 a) {
    u64 z=q23_s<K>(a),t=q23_m<K>(z,a);z=q23_s<K>(z);return q23_m<K>(z,t);
}
__device__ __constant__ u64 Q23_RC_INITIAL[48]={0xc002e754975b1623ULL,0xbca51a71fe145956ULL,0x72938ddfe774f815ULL,0xe4f2fe0de03234c8ULL,0xd5e0ba13541b6465ULL,0xec33b84cf3cc46ddULL,0x486dcb39419d4776ULL,0x6c1cb28758cc250dULL,0xe3f30d349a1436d7ULL,0xd9a64eea8dca7c45ULL,0xe59b3f3baabba1caULL,0x2a3dd4345b478ff8ULL,0xada1f8c07676ed41ULL,0x2711aa6f5509d532ULL,0x4ae6acb4c9c928b3ULL,0x56eb3d4f5256d696ULL,0x1f7a9d39923bf53aULL,0x36004261397a7f84ULL,0xe5076ddb5b72c3ecULL,0xfcd59a852c6090c9ULL,0xcd895e7068b57abaULL,0x41df7eddd730ae5aULL,0xee3e2b6c9abe9799ULL,0xd29bb7d1beb9c421ULL,0x7d5c08d2f608e39eULL,0x89ae8880aaf08048ULL,0xb35a8e7b6d2af633ULL,0xdb142332afaf518fULL,0x78f04446d48b1cb4ULL,0x26529394e47ce8a6ULL,0x999a647f69b9d34bULL,0x64b0a16a698e01efULL,0xee0b22b4dfae8bd4ULL,0x4fd53e34ca04a80aULL,0x5762bfc581f25063ULL,0xf51593c6beb5e3d9ULL,0x1e5e2b3b60e32493ULL,0x62246285f9aaaf09ULL,0xaa284b22cdb222caULL,0x63c8e713542bf418ULL,0x3ba588aecb43b5fcULL,0x23eda6d7c99150f9ULL,0xaad3be88baac9a76ULL,0xe9da8d4d9b941866ULL,0xcdb13f30d93e0268ULL,0x902cbced56f655ffULL,0x5b4e40e3c759534bULL,0xde795c04a2357b13ULL};
__device__ __constant__ u64 Q23_RC_INTERNAL[22]={0x97f7796e784ad87fULL,0xd1d2beec2f60d50cULL,0x69a3778b9f9ad222ULL,0xa9d068eaa3858e40ULL,0x295274e41eede5d1ULL,0x5874e425117bd762ULL,0x8a084b9fa8ed86e8ULL,0x3defd7485cde6441ULL,0x3998cfca871cc153ULL,0x3e52ef6fca483166ULL,0x964a208385dc9ee8ULL,0x3fcc9ecc2cc4579aULL,0x8e79b489d0096d89ULL,0x8492360ed2392572ULL,0xee72f454262574f2ULL,0x1e0e182d6da24466ULL,0x0f3a74a3215eaae2ULL,0x1b061b5aa1c0deefULL,0x192c42bc6803d7c2ULL,0xf6d49fdd97ae027cULL,0x3ec372cba0fa37a2ULL,0x5538cdd8f23445efULL};
__device__ __constant__ u64 Q23_RC_TERMINAL[48]={0x7b72c51de0ea4c8aULL,0x144573bee2ce9992ULL,0x8020289a8f35fca4ULL,0x6d36c4e62c4fe7deULL,0xa205d0e3a9b9df0fULL,0xf6e7e36f1ea6ba4bULL,0x34f7907ee5258d80ULL,0xb0464d8177b97fe6ULL,0x64ddb9b9de7e00c2ULL,0x0ed0d74027975db3ULL,0x1cbb36d5112733a7ULL,0x6673e4e9cfd0b6d6ULL,0x605f900c30872e1dULL,0x3fd5eb767e95fe6bULL,0xe8102599a24c69e9ULL,0xf7d0ce59de23f76aULL,0xf399429aa85850a5ULL,0x6d8089ecf7b71e12ULL,0xf8806b4988f49aa7ULL,0x57df2d702a321096ULL,0x16e7c1eb4d654a49ULL,0x213de225fcf33851ULL,0xb0f2b8745a097712ULL,0xd8e3cf0fbd355433ULL,0xe49868fa79d9332bULL,0x763b45b6a3821b44ULL,0x0908bf49eb0a1f29ULL,0x7691eb11194b2510ULL,0x0e4354f633ae13ceULL,0x93c393bffc2fe78bULL,0x98f6072c5d48ce06ULL,0xe3d95f14309819dcULL,0x1ef5818d3eaf6aebULL,0x0b24c19ba030fcc0ULL,0x624370a25670b343ULL,0x5f1e28455a11e4a2ULL,0xfe040503909e0447ULL,0x7257e59547fd381fULL,0xe6ae132fb82f2e94ULL,0x5711fd40f478452dULL,0xf83a424a0c08c0d8ULL,0x2cd8c9519a3ce871ULL,0x7d2ffaffb0e1728dULL,0x85ae150ccaea382dULL,0x52a345b9c7adb0d4ULL,0x504c4c35f3faeeb0ULL,0xbce34a489cfccb15ULL,0xe0a3387666fb6de5ULL};
__device__ __forceinline__ u64 q23_bias_rc(const u64* rc,int index) {
    if(rc==RC_INITIAL)return Q23_RC_INITIAL[index];
    if(rc==RC_TERMINAL)return Q23_RC_TERMINAL[index];
    return Q23_RC_INTERNAL[index];
}
template<int K> __device__ __forceinline__ void q23_biased_stage(u64 s[12],const u64* rc,int base,bool only0,bool leave) {
    if(leave){q16_group_only(s);return;}
    SmallWide b[12];
    #pragma unroll
    for(int j=0;j<12;j+=4){
        u64 x[4],x2[4],x3[4];
        #pragma unroll
        for(int i=0;i<4;i++)x[i]=s[j+i];
        #pragma unroll
        for(int i=0;i<4;i++)x2[i]=q23_s<K>(x[i]);
        #pragma unroll
        for(int i=0;i<4;i++)x3[i]=q23_m<K>(x2[i],x[i]);
        #pragma unroll
        for(int i=0;i<4;i++)x[i]=q23_s<K>(x2[i]);
        #pragma unroll
        for(int i=0;i<4;i++)b[j+i]=q23_condensed(K?q23_pair(x[i],x3[i]):product_limbs(x[i],x3[i]));
        sw_m4(b[j],b[j+1],b[j+2],b[j+3]);
    }
    #pragma unroll
    for(int j=0;j<4;j++){
        SmallWide sum=sw_add(sw_add(b[j],b[j+4]),b[j+8]);
        #pragma unroll
        for(int k=0;k<3;k++){
            int i=j+4*k;
            u64 bias=rc&&(!only0||i==0)?q23_bias_rc(rc,base+(only0?0:i)):0xffffffe30000001dULL;
            // Top <=84, not the old28 bound; same proven positive fold applies.
            s[i]=q14_fold_rc(sw_add(sum,b[i]),bias);
        }
    }
}
__device__ __constant__ u64 Q26_RC[66]={0xae182c0916d2287eULL,0xd1d2bf082f60d4f0ULL,0xf58d520747ef8162ULL,0x45e8e4a8870c2594ULL,0x69a377a79f9ad206ULL,0x8d5e0aa6b8297e78ULL,0x8615d6078af6e1b2ULL,0xa9d06906a3858e24ULL,0xcd8afc05bc143a96ULL,0x0597e201065f3943ULL,0x295275001eede5b5ULL,0x4d0d07ff377c9227ULL,0x34ba5141f8ed2ad4ULL,0x5874e441117bd746ULL,0x7c2f77402a0a83b8ULL,0x664db8bc905eda5aULL,0x8a084bbba8ed86ccULL,0xadc2debac17c333eULL,0x1a354465444fb7b3ULL,0x3defd7645cde6425ULL,0x61aa6a63756d1097ULL,0x15de3ce76e8e14c5ULL,0x3998cfe6871cc137ULL,0x5d5362e59fab6da9ULL,0x1a985c8cb1b984d8ULL,0x3e52ef8bca48314aULL,0x620d828ae2d6ddbcULL,0x728f8da06d4df25aULL,0x964a209f85dc9eccULL,0xba04b39e9e6b4b3eULL,0x1c120be91435ab0cULL,0x3fcc9ee82cc4577eULL,0x638731e7455303f0ULL,0x6abf21a6b77ac0fbULL,0x8e79b4a5d0096d6dULL,0xb23447a4e89819dfULL,0x60d7a32bb9aa78e4ULL,0x8492362ad2392556ULL,0xa84cc929eac7d1c8ULL,0xcab861710d96c864ULL,0xee72f470262574d6ULL,0x122d87703eb42147ULL,0xfa538549551397d9ULL,0x1e0e18496da2444aULL,0x41c8ab488630f0bcULL,0xeb7fe1bf08cffe55ULL,0x0f3a74bf215eaac6ULL,0x32f507be39ed5738ULL,0xf74b887689323262ULL,0x1b061b76a1c0ded3ULL,0x3ec0ae75ba4f8b45ULL,0xf571afd84f752b35ULL,0x192c42d86803d7a6ULL,0x3ce6d5d780928418ULL,0xd31a0cfa7f1f55eeULL,0xf6d49ff997ae0260ULL,0x1a8f32f9b03caed1ULL,0x1b08dfe8886b8b14ULL,0x3ec372e7a0fa3786ULL,0x627e05e6b988e3f8ULL,0x317e3af5d9a59961ULL,0x5538cdf4f23445d3ULL,0x78f360f40ac2f245ULL,0x57b8323ac85b9ffcULL,0x7b72c539e0ea4c6eULL,0x9f2d5838f978f8e0ULL};

__device__ __forceinline__ SmallWide q26_pow96(u64 x) {
    u64 x2=square(x),x3=mul(x2,x),x4=square(x2);
    return q23_condensed(product_limbs(x4,x3));
}
__device__ __forceinline__ u64 q26_raw(SmallWide v) {return ((u64)v.mid<<32)|v.lo;}
__device__ __forceinline__ Wide q30_wide(SmallWide v){return {((u64)v.mid<<32)|v.lo,(u64)v.hi};}
__device__ __forceinline__ SmallWide q30_cache(const u64 s[12]) {
    SmallWide cache=sw_from64(0xfffffffe00000002ULL);
    #pragma unroll
    for(int i=1;i<12;i++)cache=sw_add(cache,sw_from64(s[i]));
    return cache;
}
__device__ __forceinline__ Wide q26_sum(const u64 s[12],SmallWide v) {return q30_wide(sw_add(q30_cache(s),v));}
__device__ __forceinline__ u64 q26_select_rc(int round,u32 top) {return Q26_RC[3*round+top];}
__device__ __forceinline__ u64 q26_next(SmallWide v,Wide sum,int round) {
    return q14_diag_rc(q26_raw(v),DIAG[0],sum,q26_select_rc(round,v.hi));
}
__device__ __constant__ u64 Q71_DB[12]={0xe771538d3c493f72ULL,0x227dad9f27b4a216ULL,0x6841ef6af2f3c8e4ULL,0x607d75a7869b0a8fULL,0x37457906a250e744ULL,0x209d0e9e98bc43b8ULL,0x818274a5aad746caULL,0x1d6d98e653ba1da4ULL,0x9dbd84325df88282ULL,0xa2de251d0c055390ULL,0x21a97137f39c774bULL,0x170f36c92d824496ULL};
template<bool TOP0> __device__ __forceinline__ Limbs128 q71_raw(u64 a,u64 d,u64 db,u64 lo,u32 top){Limbs128 w;
if constexpr(TOP0){asm("{.reg .u32 r0,r1,r2;mad.lo.cc.u32 r0,%3,%5,%9;madc.hi.cc.u32 r1,%3,%5,%10;addc.u32 r2,%11,0;mad.lo.cc.u32 r0,%4,%7,r0;madc.hi.cc.u32 r1,%4,%7,r1;addc.u32 r2,r2,0;mad.lo.cc.u32 r1,%3,%6,r1;madc.hi.u32 r2,%3,%6,r2;mad.lo.cc.u32 r1,%4,%8,r1;madc.hi.u32 r2,%4,%8,r2;mov.u32 %0,r0;mov.u32 %1,r1;mov.u32 %2,r2;}":"=r"(w.x0),"=r"(w.x1),"=r"(w.x2):"r"((u32)a),"r"((u32)(a>>32)),"r"((u32)d),"r"((u32)(d>>32)),"r"((u32)db),"r"((u32)(db>>32)),"r"((u32)lo),"r"((u32)(lo>>32)),"r"(top));w.x3=0;}
else{asm("{.reg .u32 r0,r1,r2,r3;mad.lo.cc.u32 r0,%4,%6,%10;madc.hi.cc.u32 r1,%4,%6,%11;addc.u32 r2,%12,0;mad.lo.cc.u32 r0,%5,%8,r0;madc.hi.cc.u32 r1,%5,%8,r1;addc.u32 r2,r2,0;mad.lo.cc.u32 r1,%4,%7,r1;madc.hi.cc.u32 r2,%4,%7,r2;addc.u32 r3,0,0;mad.lo.cc.u32 r1,%5,%9,r1;madc.hi.cc.u32 r2,%5,%9,r2;addc.u32 r3,r3,0;mov.u32 %0,r0;mov.u32 %1,r1;mov.u32 %2,r2;mov.u32 %3,r3;}":"=r"(w.x0),"=r"(w.x1),"=r"(w.x2),"=r"(w.x3):"r"((u32)a),"r"((u32)(a>>32)),"r"((u32)d),"r"((u32)(d>>32)),"r"((u32)db),"r"((u32)(db>>32)),"r"((u32)lo),"r"((u32)(lo>>32)),"r"(top));}
return w;}
__device__ __forceinline__ Limbs128 q71_rc_0(u64 a,Wide sum,u64 rc){Wide z;asm("add.cc.u64 %0,%2,%4;addc.u64 %1,%3,0;":"=l"(z.lo),"=l"(z.hi):"l"(sum.lo),"l"(sum.hi),"l"(rc));return q71_raw<false>(a,DIAG[0],Q71_DB[0],z.lo,(u32)z.hi);}
__device__ __forceinline__ Limbs128 q71_rc_1(u64 a,Wide sum,u64 rc){Wide z;asm("add.cc.u64 %0,%2,%4;addc.u64 %1,%3,0;":"=l"(z.lo),"=l"(z.hi):"l"(sum.lo),"l"(sum.hi),"l"(rc));return q71_raw<true>(a,DIAG[1],Q71_DB[1],z.lo,(u32)z.hi);}
__device__ __forceinline__ Limbs128 q71_rc_2(u64 a,Wide sum,u64 rc){Wide z;asm("add.cc.u64 %0,%2,%4;addc.u64 %1,%3,0;":"=l"(z.lo),"=l"(z.hi):"l"(sum.lo),"l"(sum.hi),"l"(rc));return q71_raw<true>(a,DIAG[2],Q71_DB[2],z.lo,(u32)z.hi);}
__device__ __forceinline__ Limbs128 q71_rc_3(u64 a,Wide sum,u64 rc){Wide z;asm("add.cc.u64 %0,%2,%4;addc.u64 %1,%3,0;":"=l"(z.lo),"=l"(z.hi):"l"(sum.lo),"l"(sum.hi),"l"(rc));return q71_raw<true>(a,DIAG[3],Q71_DB[3],z.lo,(u32)z.hi);}
__device__ __forceinline__ Limbs128 q71_rc_4(u64 a,Wide sum,u64 rc){Wide z;asm("add.cc.u64 %0,%2,%4;addc.u64 %1,%3,0;":"=l"(z.lo),"=l"(z.hi):"l"(sum.lo),"l"(sum.hi),"l"(rc));return q71_raw<true>(a,DIAG[4],Q71_DB[4],z.lo,(u32)z.hi);}
__device__ __forceinline__ Limbs128 q71_rc_5(u64 a,Wide sum,u64 rc){Wide z;asm("add.cc.u64 %0,%2,%4;addc.u64 %1,%3,0;":"=l"(z.lo),"=l"(z.hi):"l"(sum.lo),"l"(sum.hi),"l"(rc));return q71_raw<true>(a,DIAG[5],Q71_DB[5],z.lo,(u32)z.hi);}
__device__ __forceinline__ Limbs128 q71_rc_6(u64 a,Wide sum,u64 rc){Wide z;asm("add.cc.u64 %0,%2,%4;addc.u64 %1,%3,0;":"=l"(z.lo),"=l"(z.hi):"l"(sum.lo),"l"(sum.hi),"l"(rc));return q71_raw<true>(a,DIAG[6],Q71_DB[6],z.lo,(u32)z.hi);}
__device__ __forceinline__ Limbs128 q71_rc_7(u64 a,Wide sum,u64 rc){Wide z;asm("add.cc.u64 %0,%2,%4;addc.u64 %1,%3,0;":"=l"(z.lo),"=l"(z.hi):"l"(sum.lo),"l"(sum.hi),"l"(rc));return q71_raw<true>(a,DIAG[7],Q71_DB[7],z.lo,(u32)z.hi);}
__device__ __forceinline__ Limbs128 q71_rc_8(u64 a,Wide sum,u64 rc){Wide z;asm("add.cc.u64 %0,%2,%4;addc.u64 %1,%3,0;":"=l"(z.lo),"=l"(z.hi):"l"(sum.lo),"l"(sum.hi),"l"(rc));return q71_raw<false>(a,DIAG[8],Q71_DB[8],z.lo,(u32)z.hi);}
__device__ __forceinline__ Limbs128 q71_rc_9(u64 a,Wide sum,u64 rc){Wide z;asm("add.cc.u64 %0,%2,%4;addc.u64 %1,%3,0;":"=l"(z.lo),"=l"(z.hi):"l"(sum.lo),"l"(sum.hi),"l"(rc));return q71_raw<false>(a,DIAG[9],Q71_DB[9],z.lo,(u32)z.hi);}
__device__ __forceinline__ Limbs128 q71_rc_10(u64 a,Wide sum,u64 rc){Wide z;asm("add.cc.u64 %0,%2,%4;addc.u64 %1,%3,0;":"=l"(z.lo),"=l"(z.hi):"l"(sum.lo),"l"(sum.hi),"l"(rc));return q71_raw<true>(a,DIAG[10],Q71_DB[10],z.lo,(u32)z.hi);}
__device__ __forceinline__ Limbs128 q71_rc_11(u64 a,Wide sum,u64 rc){Wide z;asm("add.cc.u64 %0,%2,%4;addc.u64 %1,%3,0;":"=l"(z.lo),"=l"(z.hi):"l"(sum.lo),"l"(sum.hi),"l"(rc));return q71_raw<true>(a,DIAG[11],Q71_DB[11],z.lo,(u32)z.hi);}
__device__ __forceinline__ u64 q71_next(SmallWide x,Wide sum,int round){return reduce_limbs(q71_rc_0(q26_raw(x),sum,q26_select_rc(round,x.hi)));}
__device__ __forceinline__ void q71_internal_base(u64 s[12]) {
    SmallWide others=q30_cache(s),x=q26_pow96(s[0]);
    #pragma unroll 1
    for(int round=0;round<21;round++) {
        Wide sum=q30_wide(sw_add(others,x));
        SmallWide nextx=q26_pow96(q26_next(x,sum,round));
        SmallWide next=sw_from64(0xfffffffe00000002ULL);
        #pragma unroll
        for(int i=1;i<12;i++) {
            s[i]=diag_sum(s[i],DIAG[i],sum);
            next=sw_add(next,sw_from64(s[i]));
        }
        others=next;x=nextx;
    }
    Wide sum=q30_wide(sw_add(others,x));s[0]=q26_next(x,sum,21);
    #pragma unroll
    for(int i=1;i<12;i++)s[i]=q14_diag_rc(s[i],DIAG[i],sum,RC_TERMINAL[i]);
}
__device__ __forceinline__ void q71_internal_scalar(u64 s[12]){SmallWide others=q30_cache(s),x=q26_pow96(s[0]);
#pragma unroll 1
for(int round=0;round<21;round++){Wide sum=q30_wide(sw_add(others,x));SmallWide nextx=q26_pow96(q71_next(x,sum,round));SmallWide next=sw_from64(0xfffffffe00000002ULL);
{Limbs128 w1=q71_rc_1(s[1],sum,0);
s[1]=q17_shift_positive(w1.x0,w1.x1,w1.x2);next=sw_add(next,sw_from64(s[1]));}
{Limbs128 w2=q71_rc_2(s[2],sum,0);
s[2]=q17_shift_positive(w2.x0,w2.x1,w2.x2);next=sw_add(next,sw_from64(s[2]));}
{Limbs128 w3=q71_rc_3(s[3],sum,0);
s[3]=q17_shift_positive(w3.x0,w3.x1,w3.x2);next=sw_add(next,sw_from64(s[3]));}
{Limbs128 w4=q71_rc_4(s[4],sum,0);
s[4]=q17_shift_positive(w4.x0,w4.x1,w4.x2);next=sw_add(next,sw_from64(s[4]));}
{Limbs128 w5=q71_rc_5(s[5],sum,0);
s[5]=q17_shift_positive(w5.x0,w5.x1,w5.x2);next=sw_add(next,sw_from64(s[5]));}
{Limbs128 w6=q71_rc_6(s[6],sum,0);
s[6]=q17_shift_positive(w6.x0,w6.x1,w6.x2);next=sw_add(next,sw_from64(s[6]));}
{Limbs128 w7=q71_rc_7(s[7],sum,0);
s[7]=q17_shift_positive(w7.x0,w7.x1,w7.x2);next=sw_add(next,sw_from64(s[7]));}
{Limbs128 w8=q71_rc_8(s[8],sum,0);
s[8]=reduce_limbs(w8);next=sw_add(next,sw_from64(s[8]));}
{Limbs128 w9=q71_rc_9(s[9],sum,0);
s[9]=reduce_limbs(w9);next=sw_add(next,sw_from64(s[9]));}
{Limbs128 w10=q71_rc_10(s[10],sum,0);
s[10]=q17_shift_positive(w10.x0,w10.x1,w10.x2);next=sw_add(next,sw_from64(s[10]));}
{Limbs128 w11=q71_rc_11(s[11],sum,0);
s[11]=q17_shift_positive(w11.x0,w11.x1,w11.x2);next=sw_add(next,sw_from64(s[11]));}
others=next;x=nextx;}Wide sum=q30_wide(sw_add(others,x));s[0]=q71_next(x,sum,21);
{Limbs128 w1=q71_rc_1(s[1],sum,RC_TERMINAL[1]);
s[1]=q17_shift_positive(w1.x0,w1.x1,w1.x2);}
{Limbs128 w2=q71_rc_2(s[2],sum,RC_TERMINAL[2]);
s[2]=q17_shift_positive(w2.x0,w2.x1,w2.x2);}
{Limbs128 w3=q71_rc_3(s[3],sum,RC_TERMINAL[3]);
s[3]=q17_shift_positive(w3.x0,w3.x1,w3.x2);}
{Limbs128 w4=q71_rc_4(s[4],sum,RC_TERMINAL[4]);
s[4]=q17_shift_positive(w4.x0,w4.x1,w4.x2);}
{Limbs128 w5=q71_rc_5(s[5],sum,RC_TERMINAL[5]);
s[5]=q17_shift_positive(w5.x0,w5.x1,w5.x2);}
{Limbs128 w6=q71_rc_6(s[6],sum,RC_TERMINAL[6]);
s[6]=q17_shift_positive(w6.x0,w6.x1,w6.x2);}
{Limbs128 w7=q71_rc_7(s[7],sum,RC_TERMINAL[7]);
s[7]=q17_shift_positive(w7.x0,w7.x1,w7.x2);}
{Limbs128 w8=q71_rc_8(s[8],sum,RC_TERMINAL[8]);
s[8]=reduce_limbs(w8);}
{Limbs128 w9=q71_rc_9(s[9],sum,RC_TERMINAL[9]);
s[9]=reduce_limbs(w9);}
{Limbs128 w10=q71_rc_10(s[10],sum,RC_TERMINAL[10]);
s[10]=q17_shift_positive(w10.x0,w10.x1,w10.x2);}
{Limbs128 w11=q71_rc_11(s[11],sum,RC_TERMINAL[11]);
s[11]=q17_shift_positive(w11.x0,w11.x1,w11.x2);}
}
__device__ __forceinline__ void q71_internal_group4(u64 s[12]){SmallWide others=q30_cache(s),x=q26_pow96(s[0]);
#pragma unroll 1
for(int round=0;round<21;round++){Wide sum=q30_wide(sw_add(others,x));SmallWide nextx=q26_pow96(q71_next(x,sum,round));SmallWide next=sw_from64(0xfffffffe00000002ULL);
{Limbs128 w1=q71_rc_1(s[1],sum,0);
Limbs128 w2=q71_rc_2(s[2],sum,0);
Limbs128 w3=q71_rc_3(s[3],sum,0);
Limbs128 w4=q71_rc_4(s[4],sum,0);
s[1]=q17_shift_positive(w1.x0,w1.x1,w1.x2);next=sw_add(next,sw_from64(s[1]));
s[2]=q17_shift_positive(w2.x0,w2.x1,w2.x2);next=sw_add(next,sw_from64(s[2]));
s[3]=q17_shift_positive(w3.x0,w3.x1,w3.x2);next=sw_add(next,sw_from64(s[3]));
s[4]=q17_shift_positive(w4.x0,w4.x1,w4.x2);next=sw_add(next,sw_from64(s[4]));}
{Limbs128 w5=q71_rc_5(s[5],sum,0);
Limbs128 w6=q71_rc_6(s[6],sum,0);
Limbs128 w7=q71_rc_7(s[7],sum,0);
Limbs128 w8=q71_rc_8(s[8],sum,0);
s[5]=q17_shift_positive(w5.x0,w5.x1,w5.x2);next=sw_add(next,sw_from64(s[5]));
s[6]=q17_shift_positive(w6.x0,w6.x1,w6.x2);next=sw_add(next,sw_from64(s[6]));
s[7]=q17_shift_positive(w7.x0,w7.x1,w7.x2);next=sw_add(next,sw_from64(s[7]));
s[8]=reduce_limbs(w8);next=sw_add(next,sw_from64(s[8]));}
{Limbs128 w9=q71_rc_9(s[9],sum,0);
Limbs128 w10=q71_rc_10(s[10],sum,0);
Limbs128 w11=q71_rc_11(s[11],sum,0);
s[9]=reduce_limbs(w9);next=sw_add(next,sw_from64(s[9]));
s[10]=q17_shift_positive(w10.x0,w10.x1,w10.x2);next=sw_add(next,sw_from64(s[10]));
s[11]=q17_shift_positive(w11.x0,w11.x1,w11.x2);next=sw_add(next,sw_from64(s[11]));}
others=next;x=nextx;}Wide sum=q30_wide(sw_add(others,x));s[0]=q71_next(x,sum,21);
{Limbs128 w1=q71_rc_1(s[1],sum,RC_TERMINAL[1]);
Limbs128 w2=q71_rc_2(s[2],sum,RC_TERMINAL[2]);
Limbs128 w3=q71_rc_3(s[3],sum,RC_TERMINAL[3]);
Limbs128 w4=q71_rc_4(s[4],sum,RC_TERMINAL[4]);
s[1]=q17_shift_positive(w1.x0,w1.x1,w1.x2);
s[2]=q17_shift_positive(w2.x0,w2.x1,w2.x2);
s[3]=q17_shift_positive(w3.x0,w3.x1,w3.x2);
s[4]=q17_shift_positive(w4.x0,w4.x1,w4.x2);}
{Limbs128 w5=q71_rc_5(s[5],sum,RC_TERMINAL[5]);
Limbs128 w6=q71_rc_6(s[6],sum,RC_TERMINAL[6]);
Limbs128 w7=q71_rc_7(s[7],sum,RC_TERMINAL[7]);
Limbs128 w8=q71_rc_8(s[8],sum,RC_TERMINAL[8]);
s[5]=q17_shift_positive(w5.x0,w5.x1,w5.x2);
s[6]=q17_shift_positive(w6.x0,w6.x1,w6.x2);
s[7]=q17_shift_positive(w7.x0,w7.x1,w7.x2);
s[8]=reduce_limbs(w8);}
{Limbs128 w9=q71_rc_9(s[9],sum,RC_TERMINAL[9]);
Limbs128 w10=q71_rc_10(s[10],sum,RC_TERMINAL[10]);
Limbs128 w11=q71_rc_11(s[11],sum,RC_TERMINAL[11]);
s[9]=reduce_limbs(w9);
s[10]=q17_shift_positive(w10.x0,w10.x1,w10.x2);
s[11]=q17_shift_positive(w11.x0,w11.x1,w11.x2);}
}
__device__ __forceinline__ void q14_internal(u64 s[12]){q71_internal_group4(s);}
extern "C" __global__ void q26_internal_probe(const u64* input,u32 count,u64* output) {
    u32 i=blockIdx.x*blockDim.x+threadIdx.x;if(i>=count)return;
    const u64* in=input+13*i;u64 s[12];
    SmallWide v={(u32)in[0],(u32)(in[0]>>32),(u32)in[12]};
    for(int j=0;j<12;j++)s[j]=in[j];
    Wide sum=q26_sum(s,v);
    // All 22 RC choices, arbitrary forced raw/top including rare negative net carry.
    for(int phase=0;phase<22;phase++) {
        output[32+278*i+12*phase]=canon(q26_next(v,sum,phase));
        #pragma unroll
        for(int j=1;j<12;j++)output[32+278*i+12*phase+j]=canon(q14_diag_rc(s[j],DIAG[j],sum,phase==21?RC_TERMINAL[j]:0));
    }
    q14_internal(s);
    for(int j=0;j<12;j++)output[32+278*i+264+j]=canon(s[j]);
    v=q26_pow96(in[0]);output[32+278*i+276]=q26_raw(v);output[32+278*i+277]=v.hi;
}
extern "C" __global__ void q16_group_probe(const u64* input,u32 count,u64* output) {
    u32 i=blockIdx.x*blockDim.x+threadIdx.x;if(i>=count)return;
    u64 a[12],b[12];
    #pragma unroll
    for(int j=0;j<12;j++)a[j]=b[j]=input[12*i+j];
    q16_group_only(a);q16_fused_stage(b,RC_INITIAL,0,false,false);
    #pragma unroll
    for(int j=0;j<12;j++){output[32+24*i+j]=canon(a[j]);output[44+24*i+j]=canon(b[j]);}
}

__device__ __forceinline__ void q14_rounds(u64 s[12],int start,bool biased,bool leave_final) {
    if(!biased) {
        #pragma unroll
        for(int i=0;i<12;i++)s[i]=add_rc(s[i],RC_INITIAL[12*start+i]);
    }
    #pragma unroll 1
    for(int round=start;round<3;round++)q23_biased_stage<0>(s,RC_INITIAL,12*(round+1),false,false);
    q23_biased_stage<0>(s,RC_INTERNAL,0,true,false);
    q14_internal(s);
    #pragma unroll 1
    for(int round=0;round<3;round++)q23_biased_stage<0>(s,RC_TERMINAL,12*(round+1),false,false);
    q23_biased_stage<0>(s,0,0,false,leave_final);
}
__device__ __forceinline__ void q14_permute(u64 s[12]) {
    q14_mix(s,RC_INITIAL,0,false);q14_rounds(s,0,true,false);
}
__device__ __forceinline__ void q14_prefix(const u64* pre,u64 local,u64 s[12],bool leave_final) {
    sparse_first(pre,local,s);q14_rounds(s,1,false,false);
    s[0]=add(s[0],1);s[1]=add(s[1],1);
    q14_mix(s,RC_INITIAL,0,false);q14_rounds(s,0,true,leave_final);
}

__device__ __forceinline__ u64 q14_row0(u64 a,u64 b,u64 c,u64 d) {
    u64 ab=add(a,b),t=add(add(ab,c),d);return add(add(t,ab),b);
}
__device__ __forceinline__ bool q14_filter64(u64 s[12],const u64* target) {
    // Sixteen adds, exact first output. Equal high64 always computes rest.
    u64 row=q14_row0(s[0],s[1],s[2],s[3]);
    u64 other=q14_row0(add(s[4],s[8]),add(s[5],s[9]),add(s[6],s[10]),add(s[7],s[11]));
    u64 first=swap64(canon(add(add(row,row),other)));
    if(first<target[0])return true;
    if(first>target[0])return false;
    q13_final4(s);return prefix_le(s,target);
}
__device__ __constant__ u64 Q25_RC[96]={0xada1f8c07676ed41ULL,0x2711aa6f5509d532ULL,0x4ae6acb4c9c928b3ULL,0x56eb3d4f5256d696ULL,0x1f7a9d39923bf53aULL,0x36004261397a7f84ULL,0xe5076ddb5b72c3ecULL,0xfcd59a852c6090c9ULL,0xcd895e7068b57abaULL,0x41df7eddd730ae5aULL,0xee3e2b6c9abe9799ULL,0xd29bb7d1beb9c421ULL,0x7d5c08d2f608e39eULL,0x89ae8880aaf08048ULL,0xb35a8e7b6d2af633ULL,0xdb142332afaf518fULL,0x78f04446d48b1cb4ULL,0x26529394e47ce8a6ULL,0x999a647f69b9d34bULL,0x64b0a16a698e01efULL,0xee0b22b4dfae8bd4ULL,0x4fd53e34ca04a80aULL,0x5762bfc581f25063ULL,0xf51593c6beb5e3d9ULL,0x1e5e2b3b60e32493ULL,0x62246285f9aaaf09ULL,0xaa284b22cdb222caULL,0x63c8e713542bf418ULL,0x3ba588aecb43b5fcULL,0x23eda6d7c99150f9ULL,0xaad3be88baac9a76ULL,0xe9da8d4d9b941866ULL,0xcdb13f30d93e0268ULL,0x902cbced56f655ffULL,0x5b4e40e3c759534bULL,0xde795c04a2357b13ULL,0x97f7796e784ad87fULL,0xffffffe30000001dULL,0xffffffe30000001dULL,0xffffffe30000001dULL,0xffffffe30000001dULL,0xffffffe30000001dULL,0xffffffe30000001dULL,0xffffffe30000001dULL,0xffffffe30000001dULL,0xffffffe30000001dULL,0xffffffe30000001dULL,0xffffffe30000001dULL,0x605f900c30872e1dULL,0x3fd5eb767e95fe6bULL,0xe8102599a24c69e9ULL,0xf7d0ce59de23f76aULL,0xf399429aa85850a5ULL,0x6d8089ecf7b71e12ULL,0xf8806b4988f49aa7ULL,0x57df2d702a321096ULL,0x16e7c1eb4d654a49ULL,0x213de225fcf33851ULL,0xb0f2b8745a097712ULL,0xd8e3cf0fbd355433ULL,0xe49868fa79d9332bULL,0x763b45b6a3821b44ULL,0x0908bf49eb0a1f29ULL,0x7691eb11194b2510ULL,0x0e4354f633ae13ceULL,0x93c393bffc2fe78bULL,0x98f6072c5d48ce06ULL,0xe3d95f14309819dcULL,0x1ef5818d3eaf6aebULL,0x0b24c19ba030fcc0ULL,0x624370a25670b343ULL,0x5f1e28455a11e4a2ULL,0xfe040503909e0447ULL,0x7257e59547fd381fULL,0xe6ae132fb82f2e94ULL,0x5711fd40f478452dULL,0xf83a424a0c08c0d8ULL,0x2cd8c9519a3ce871ULL,0x7d2ffaffb0e1728dULL,0x85ae150ccaea382dULL,0x52a345b9c7adb0d4ULL,0x504c4c35f3faeeb0ULL,0xbce34a489cfccb15ULL,0xe0a3387666fb6de5ULL,0xffffffe30000001dULL,0xffffffe30000001dULL,0xffffffe30000001dULL,0xffffffe30000001dULL,0xffffffe30000001dULL,0xffffffe30000001dULL,0xffffffe30000001dULL,0xffffffe30000001dULL,0xffffffe30000001dULL,0xffffffe30000001dULL,0xffffffe30000001dULL,0xffffffe30000001dULL};
template<int K> __device__ __forceinline__ void q25_table_stage(u64 s[12],int phase,bool leave) {
    if(leave){q16_group_only(s);return;}
    SmallWide b[12];
    #pragma unroll
    for(int j=0;j<12;j+=4){
        u64 x[4],x2[4],x3[4];
        #pragma unroll
        for(int i=0;i<4;i++)x[i]=s[j+i];
        #pragma unroll
        for(int i=0;i<4;i++)x2[i]=q23_s<K>(x[i]);
        #pragma unroll
        for(int i=0;i<4;i++)x3[i]=q23_m<K>(x2[i],x[i]);
        #pragma unroll
        for(int i=0;i<4;i++)x[i]=q23_s<K>(x2[i]);
        #pragma unroll
        for(int i=0;i<4;i++)b[j+i]=q23_condensed(K?q23_pair(x[i],x3[i]):product_limbs(x[i],x3[i]));
        sw_m4(b[j],b[j+1],b[j+2],b[j+3]);
    }
    #pragma unroll
    for(int j=0;j<4;j++){
        SmallWide sum=sw_add(sw_add(b[j],b[j+4]),b[j+8]);
        #pragma unroll
        for(int k=0;k<3;k++){
            int i=j+4*k;
            u64 bias=Q25_RC[12*phase+i];
            // Top <=84, not the old28 bound; same proven positive fold applies.
            s[i]=q14_fold_rc(sw_add(sum,b[i]),bias);
        }
    }
}

template<int K> __device__ __forceinline__ void q25_phase(u64 s[12],int phase,bool leave) {
    if(K)q25_table_stage<0>(s,phase,leave);
    else {
        const u64* rc=phase<3?RC_INITIAL:phase==3?RC_INTERNAL:phase<7?RC_TERMINAL:0;
        int base=phase<3?12*(phase+1):phase<7?12*(phase-3):0;
        q23_biased_stage<0>(s,rc,base,phase==3,leave);
    }
}
template<int K> __device__ __forceinline__ void q25_prefix(const u64* pre,u64 local,u64 s[12],bool leave_final) {
    sparse_first(pre,local,s);
    #pragma unroll
    for(int perm=0;perm<2;perm++) {
        if(perm==0) {
            #pragma unroll
            for(int i=0;i<12;i++)s[i]=add_rc(s[i],RC_INITIAL[12+i]);
        } else {
            s[0]=add(s[0],1);s[1]=add(s[1],1);q14_mix(s,RC_INITIAL,0,false);
        }
        // Both loop counters become compile-time constants; internal21 loop remains shared in each permutation.
        #pragma unroll
        for(int phase=perm==0?1:0;phase<8;phase++) {
            q25_phase<K>(s,phase,perm==1&&phase==7&&leave_final);
            if(phase==3)q14_internal(s);
        }
    }
}

extern "C" __global__ void quantus_sparse_mine(const u64* pre,const u64* target,
    u64 counter,u32 count,u32 capacity,u32* result) {
    u32 i=blockIdx.x*blockDim.x+threadIdx.x;if(i>=count)return;
    u64 s[12];q25_prefix<1>(pre,counter+i,s,true);
    bool pass=q14_filter64(s,target);
    if(pass){u32 p=atomicAdd(result,1U);if(p<capacity)result[p+1]=i;}
}

extern "C" __global__ void quantus_sparse_hashes(const u64* pre,u64 counter,u32 count,u64* output) {
    u32 i=blockIdx.x*blockDim.x+threadIdx.x;if(i>=count)return;
    u64 s[12];q25_prefix<1>(pre,counter+i,s,false);
    #pragma unroll
    for(int w=0;w<4;w++)output[32+w*count+i]=canon(s[w]);
    q14_permute(s);
    #pragma unroll
    for(int w=0;w<4;w++)output[32+(w+4)*count+i]=canon(s[w]);
}
extern "C" __global__ void quantus_sparse_first(const u64* pre,u64 counter,u32 count,u64* output) {
    u32 i=blockIdx.x*blockDim.x+threadIdx.x;if(i>=count)return;
    u64 s[12];sparse_first(pre,counter+i,s);
    #pragma unroll
    for(int w=0;w<12;w++)output[32+12*i+w]=canon(s[w]);
}

extern "C" __global__ void quantus_q14_fused_layers(const u64* input,u32 count,u64* output) {
    u32 i=blockIdx.x*blockDim.x+threadIdx.x;if(i>=count)return;
    u64 a[12],b[12];
    #pragma unroll
    for(int j=0;j<12;j++)a[j]=b[j]=input[12*i+j];
    q14_mix(a,RC_INITIAL,0,false);
    b[0]=add_rc(b[0],RC_INTERNAL[0]);q14_internal(b);
    #pragma unroll
    for(int j=0;j<12;j++){output[32+24*i+j]=canon(a[j]);output[44+24*i+j]=canon(b[j]);}
}
extern "C" __global__ void quantus_q14_fused_fold(const u64* input,u32 count,u64* output) {
    u32 i=blockIdx.x*blockDim.x+threadIdx.x;if(i>=count)return;
    SmallWide w=sw_from64(input[3*i]);w.hi=(u32)input[3*i+1];
    output[32+i]=canon(q14_fold_rc(w,input[3*i+2]));
}

__device__ __forceinline__ u64 q15_mont(Limbs128 w) {
    // R=B-1, N/R = (w1+w2)+B*(w3-w0-w1) mod p.
    // Normalize low limb before interpreting signed high: q in {-2,-1,0}.
    // Correction q*EPS is implemented as low+=-q, high+=q, with borrow fold.
    u32 lo,hi;
    asm("{.reg .u32 l,m,q,c,k,d,b;\n\t"
        "add.cc.u32 l,%3,%4;addc.u32 c,0,0;\n\t"
        "sub.cc.u32 m,%5,%2;subc.u32 q,0,0;\n\t"
        "sub.cc.u32 m,m,%3;subc.u32 q,q,0;\n\t"
        "add.cc.u32 m,m,c;addc.u32 q,q,0;\n\t"
        "neg.s32 k,q;add.cc.u32 l,l,k;addc.u32 c,0,0;\n\t"
        "sub.u32 d,k,c;sub.cc.u32 m,m,d;subc.u32 b,0,0;\n\t"
        "sub.cc.u32 l,l,b;subc.u32 m,m,0;\n\t"
        "mov.u32 %0,l;mov.u32 %1,m;}"
        :"=r"(lo),"=r"(hi):"r"(w.x0),"r"(w.x1),"r"(w.x2),"r"(w.x3));
    return ((u64)hi<<32)|lo;
}
__device__ __forceinline__ u64 q15_mmul(u64 a,u64 b) {return q15_mont(product_limbs(a,b));}
__device__ __forceinline__ u64 q15_msquare(u64 a) {
    Wide w=square128(a);return q15_mont({(u32)w.lo,(u32)(w.lo>>32),(u32)w.hi,(u32)(w.hi>>32)});
}
__device__ __forceinline__ u64 q15_mpow7(u64 x) {
    u64 x2=q15_msquare(x),x3=q15_mmul(x2,x),x4=q15_msquare(x2);return q15_mmul(x4,x3);
}
extern "C" __global__ void q15_reduce_probe(const u64* input,u32 count,u64* output) {
    u32 i=blockIdx.x*blockDim.x+threadIdx.x;if(i>=count)return;
    u64 a=input[2*i],b=input[2*i+1];Limbs128 w={(u32)a,(u32)(a>>32),(u32)b,(u32)(b>>32)};
    output[32+2*i]=canon(q15_reduce(w.x0,w.x1,w.x2,w.x3));
    output[33+2*i]=canon(q15_mont(w));
}
extern "C" __global__ void q15_mont_probe(const u64* input,u32 count,u64* output) {
    u32 i=blockIdx.x*blockDim.x+threadIdx.x;if(i>=count)return;
    u64 a=input[2*i],b=input[2*i+1];
    output[32+3*i]=canon(q15_mmul(a,b));output[33+3*i]=canon(q15_msquare(a));output[34+3*i]=canon(q15_mpow7(a));
}
template<int MODE,int WIDTH> __device__ __forceinline__ void q15_chain(u64* output,u32 repeats) {
    u32 i=blockIdx.x*blockDim.x+threadIdx.x;u64 x[WIDTH];
    #pragma unroll
    for(int j=0;j<WIDTH;j++)x[j]=123456789ULL+i+((u64)j<<32);
    #pragma unroll 1
    for(u32 n=0;n<repeats;n++) {
        #pragma unroll
        for(int j=0;j<WIDTH;j++)x[j]=MODE==0?pow7(x[j]):q15_mpow7(x[j]);
    }
    #pragma unroll
    for(int j=0;j<WIDTH;j++)output[WIDTH*i+j]=x[j];
}
extern "C" __global__ void q15_normal1(u64* output,u32 repeats){q15_chain<0,1>(output,repeats);}
extern "C" __global__ void q15_normal4(u64* output,u32 repeats){q15_chain<0,4>(output,repeats);}
extern "C" __global__ void q15_mont1(u64* output,u32 repeats){q15_chain<1,1>(output,repeats);}
extern "C" __global__ void q15_mont4(u64* output,u32 repeats){q15_chain<1,4>(output,repeats);}

extern "C" __global__ void q38_product_probe(const u64* input,u32 count,u64* output) {
    u32 k=blockIdx.x*blockDim.x+threadIdx.x;if(k>=count)return;
    const u64* in=input+4*k;
    Limbs128 a=q38_mac(in[0],in[1],0,0),b=q38_mac(in[0],in[1],in[2],(u32)in[3]);
    output[32+5*k]=((u64)a.x1<<32)|a.x0;output[33+5*k]=((u64)a.x3<<32)|a.x2;
    output[34+5*k]=((u64)b.x1<<32)|b.x0;output[35+5*k]=((u64)b.x3<<32)|b.x2;
    output[36+5*k]=canon(reduce_limbs(b));
}

extern "C" __global__ void q53_product_probe(const u64* pairs,u32 count,u64* output){u32 i=blockIdx.x*blockDim.x+threadIdx.x;if(i>=count)return;u64 a=pairs[2*i],b=pairs[2*i+1];Limbs128 w=product_limbs(a,b);SmallWide v=q23_condensed(w);output[32+6*i]=((u64)w.x1<<32)|w.x0;output[33+6*i]=((u64)w.x3<<32)|w.x2;output[34+6*i]=canon(reduce_limbs(w));output[35+6*i]=((u64)v.mid<<32)|v.lo;output[36+6*i]=v.hi;output[37+6*i]=canon(pow7(a));}
extern "C" __global__ void q71_raw_0(const u64* input,u32 count,u32* output){u32 k=blockIdx.x*blockDim.x+threadIdx.x;if(k>=count)return;Limbs128 w=q71_raw<false>(input[3*k],DIAG[0],Q71_DB[0],input[3*k+1],(u32)input[3*k+2]);u64 f=canon(reduce_limbs(w));output[32+6*k]=w.x0;output[33+6*k]=w.x1;output[34+6*k]=w.x2;output[35+6*k]=w.x3;output[36+6*k]=(u32)f;output[37+6*k]=(u32)(f>>32);}
extern "C" __global__ void q71_raw_1(const u64* input,u32 count,u32* output){u32 k=blockIdx.x*blockDim.x+threadIdx.x;if(k>=count)return;Limbs128 w=q71_raw<true>(input[3*k],DIAG[1],Q71_DB[1],input[3*k+1],(u32)input[3*k+2]);u64 f=canon(reduce_limbs(w));output[32+6*k]=w.x0;output[33+6*k]=w.x1;output[34+6*k]=w.x2;output[35+6*k]=w.x3;output[36+6*k]=(u32)f;output[37+6*k]=(u32)(f>>32);}
extern "C" __global__ void q71_raw_2(const u64* input,u32 count,u32* output){u32 k=blockIdx.x*blockDim.x+threadIdx.x;if(k>=count)return;Limbs128 w=q71_raw<true>(input[3*k],DIAG[2],Q71_DB[2],input[3*k+1],(u32)input[3*k+2]);u64 f=canon(reduce_limbs(w));output[32+6*k]=w.x0;output[33+6*k]=w.x1;output[34+6*k]=w.x2;output[35+6*k]=w.x3;output[36+6*k]=(u32)f;output[37+6*k]=(u32)(f>>32);}
extern "C" __global__ void q71_raw_3(const u64* input,u32 count,u32* output){u32 k=blockIdx.x*blockDim.x+threadIdx.x;if(k>=count)return;Limbs128 w=q71_raw<true>(input[3*k],DIAG[3],Q71_DB[3],input[3*k+1],(u32)input[3*k+2]);u64 f=canon(reduce_limbs(w));output[32+6*k]=w.x0;output[33+6*k]=w.x1;output[34+6*k]=w.x2;output[35+6*k]=w.x3;output[36+6*k]=(u32)f;output[37+6*k]=(u32)(f>>32);}
extern "C" __global__ void q71_raw_4(const u64* input,u32 count,u32* output){u32 k=blockIdx.x*blockDim.x+threadIdx.x;if(k>=count)return;Limbs128 w=q71_raw<true>(input[3*k],DIAG[4],Q71_DB[4],input[3*k+1],(u32)input[3*k+2]);u64 f=canon(reduce_limbs(w));output[32+6*k]=w.x0;output[33+6*k]=w.x1;output[34+6*k]=w.x2;output[35+6*k]=w.x3;output[36+6*k]=(u32)f;output[37+6*k]=(u32)(f>>32);}
extern "C" __global__ void q71_raw_5(const u64* input,u32 count,u32* output){u32 k=blockIdx.x*blockDim.x+threadIdx.x;if(k>=count)return;Limbs128 w=q71_raw<true>(input[3*k],DIAG[5],Q71_DB[5],input[3*k+1],(u32)input[3*k+2]);u64 f=canon(reduce_limbs(w));output[32+6*k]=w.x0;output[33+6*k]=w.x1;output[34+6*k]=w.x2;output[35+6*k]=w.x3;output[36+6*k]=(u32)f;output[37+6*k]=(u32)(f>>32);}
extern "C" __global__ void q71_raw_6(const u64* input,u32 count,u32* output){u32 k=blockIdx.x*blockDim.x+threadIdx.x;if(k>=count)return;Limbs128 w=q71_raw<true>(input[3*k],DIAG[6],Q71_DB[6],input[3*k+1],(u32)input[3*k+2]);u64 f=canon(reduce_limbs(w));output[32+6*k]=w.x0;output[33+6*k]=w.x1;output[34+6*k]=w.x2;output[35+6*k]=w.x3;output[36+6*k]=(u32)f;output[37+6*k]=(u32)(f>>32);}
extern "C" __global__ void q71_raw_7(const u64* input,u32 count,u32* output){u32 k=blockIdx.x*blockDim.x+threadIdx.x;if(k>=count)return;Limbs128 w=q71_raw<true>(input[3*k],DIAG[7],Q71_DB[7],input[3*k+1],(u32)input[3*k+2]);u64 f=canon(reduce_limbs(w));output[32+6*k]=w.x0;output[33+6*k]=w.x1;output[34+6*k]=w.x2;output[35+6*k]=w.x3;output[36+6*k]=(u32)f;output[37+6*k]=(u32)(f>>32);}
extern "C" __global__ void q71_raw_8(const u64* input,u32 count,u32* output){u32 k=blockIdx.x*blockDim.x+threadIdx.x;if(k>=count)return;Limbs128 w=q71_raw<false>(input[3*k],DIAG[8],Q71_DB[8],input[3*k+1],(u32)input[3*k+2]);u64 f=canon(reduce_limbs(w));output[32+6*k]=w.x0;output[33+6*k]=w.x1;output[34+6*k]=w.x2;output[35+6*k]=w.x3;output[36+6*k]=(u32)f;output[37+6*k]=(u32)(f>>32);}
extern "C" __global__ void q71_raw_9(const u64* input,u32 count,u32* output){u32 k=blockIdx.x*blockDim.x+threadIdx.x;if(k>=count)return;Limbs128 w=q71_raw<false>(input[3*k],DIAG[9],Q71_DB[9],input[3*k+1],(u32)input[3*k+2]);u64 f=canon(reduce_limbs(w));output[32+6*k]=w.x0;output[33+6*k]=w.x1;output[34+6*k]=w.x2;output[35+6*k]=w.x3;output[36+6*k]=(u32)f;output[37+6*k]=(u32)(f>>32);}
extern "C" __global__ void q71_raw_10(const u64* input,u32 count,u32* output){u32 k=blockIdx.x*blockDim.x+threadIdx.x;if(k>=count)return;Limbs128 w=q71_raw<true>(input[3*k],DIAG[10],Q71_DB[10],input[3*k+1],(u32)input[3*k+2]);u64 f=canon(reduce_limbs(w));output[32+6*k]=w.x0;output[33+6*k]=w.x1;output[34+6*k]=w.x2;output[35+6*k]=w.x3;output[36+6*k]=(u32)f;output[37+6*k]=(u32)(f>>32);}
extern "C" __global__ void q71_raw_11(const u64* input,u32 count,u32* output){u32 k=blockIdx.x*blockDim.x+threadIdx.x;if(k>=count)return;Limbs128 w=q71_raw<true>(input[3*k],DIAG[11],Q71_DB[11],input[3*k+1],(u32)input[3*k+2]);u64 f=canon(reduce_limbs(w));output[32+6*k]=w.x0;output[33+6*k]=w.x1;output[34+6*k]=w.x2;output[35+6*k]=w.x3;output[36+6*k]=(u32)f;output[37+6*k]=(u32)(f>>32);}
extern "C" __global__ void q71_chain_base(const u64* input,u32 count,u32 reps,u64* output){u32 i=blockIdx.x*blockDim.x+threadIdx.x;if(i>=count)return;u64 s[12];
#pragma unroll
for(int j=0;j<12;j++)s[j]=input[12*i+j];
#pragma unroll 1
for(u32 k=0;k<reps;k++)q71_internal_base(s);
#pragma unroll
for(int j=0;j<12;j++)output[32+12*i+j]=canon(s[j]);}
extern "C" __global__ void q71_chain_scalar(const u64* input,u32 count,u32 reps,u64* output){u32 i=blockIdx.x*blockDim.x+threadIdx.x;if(i>=count)return;u64 s[12];
#pragma unroll
for(int j=0;j<12;j++)s[j]=input[12*i+j];
#pragma unroll 1
for(u32 k=0;k<reps;k++)q71_internal_scalar(s);
#pragma unroll
for(int j=0;j<12;j++)output[32+12*i+j]=canon(s[j]);}
extern "C" __global__ void q71_chain_group4(const u64* input,u32 count,u32 reps,u64* output){u32 i=blockIdx.x*blockDim.x+threadIdx.x;if(i>=count)return;u64 s[12];
#pragma unroll
for(int j=0;j<12;j++)s[j]=input[12*i+j];
#pragma unroll 1
for(u32 k=0;k<reps;k++)q71_internal_group4(s);
#pragma unroll
for(int j=0;j<12;j++)output[32+12*i+j]=canon(s[j]);}

extern "C" __global__ void q71_positive_reduce(const u32* input,u32 count,u64* output){u32 k=blockIdx.x*blockDim.x+threadIdx.x;if(k>=count)return;output[32+k]=canon(q17_shift_positive(input[3*k],input[3*k+1],input[3*k+2]));}


alias F = vec2<u32>;
struct Acc { bajo: u32, alto: u32, acarreo: u32 }
struct Resultados {
  cuenta: atomic<u32>,
  indices: array<u32, 256>,
}
struct Parametros {
  preestado: array<vec4<u32>, 12>,
  objetivo: array<vec4<u32>, 2>,
  lote: vec4<u32>,
}
struct Constantes { valores: array<vec4<u32>, 118> }
const constantesFijas: array<vec4<u32>, 118> = array<vec4<u32>, 118>(
    vec4<u32>(0x784ad863u, 0x97f7798au, 0u, 0u),
    vec4<u32>(0x2f60d4f0u, 0xd1d2bf08u, 0u, 0u),
    vec4<u32>(0x9f9ad206u, 0x69a377a7u, 0u, 0u),
    vec4<u32>(0xa3858e24u, 0xa9d06906u, 0u, 0u),
    vec4<u32>(0x1eede5b5u, 0x29527500u, 0u, 0u),
    vec4<u32>(0x117bd746u, 0x5874e441u, 0u, 0u),
    vec4<u32>(0xa8ed86ccu, 0x8a084bbbu, 0u, 0u),
    vec4<u32>(0x5cde6425u, 0x3defd764u, 0u, 0u),
    vec4<u32>(0x871cc137u, 0x3998cfe6u, 0u, 0u),
    vec4<u32>(0xca48314au, 0x3e52ef8bu, 0u, 0u),
    vec4<u32>(0x85dc9eccu, 0x964a209fu, 0u, 0u),
    vec4<u32>(0x2cc4577eu, 0x3fcc9ee8u, 0u, 0u),
    vec4<u32>(0xd0096d6du, 0x8e79b4a5u, 0u, 0u),
    vec4<u32>(0xd2392556u, 0x8492362au, 0u, 0u),
    vec4<u32>(0x262574d6u, 0xee72f470u, 0u, 0u),
    vec4<u32>(0x6da2444au, 0x1e0e1849u, 0u, 0u),
    vec4<u32>(0x215eaac6u, 0xf3a74bfu, 0u, 0u),
    vec4<u32>(0xa1c0ded3u, 0x1b061b76u, 0u, 0u),
    vec4<u32>(0x6803d7a6u, 0x192c42d8u, 0u, 0u),
    vec4<u32>(0x97ae0260u, 0xf6d49ff9u, 0u, 0u),
    vec4<u32>(0xa0fa3786u, 0x3ec372e7u, 0u, 0u),
    vec4<u32>(0xf23445d3u, 0x5538cdf4u, 0u, 0u),
    vec4<u32>(0x975b1607u, 0xc002e770u, 0u, 0u),
    vec4<u32>(0xfe14593au, 0xbca51a8du, 0u, 0u),
    vec4<u32>(0xe774f7f9u, 0x72938dfbu, 0u, 0u),
    vec4<u32>(0xe03234acu, 0xe4f2fe29u, 0u, 0u),
    vec4<u32>(0x541b6449u, 0xd5e0ba2fu, 0u, 0u),
    vec4<u32>(0xf3cc46c1u, 0xec33b868u, 0u, 0u),
    vec4<u32>(0x419d475au, 0x486dcb55u, 0u, 0u),
    vec4<u32>(0x58cc24f1u, 0x6c1cb2a3u, 0u, 0u),
    vec4<u32>(0x9a1436bbu, 0xe3f30d50u, 0u, 0u),
    vec4<u32>(0x8dca7c29u, 0xd9a64f06u, 0u, 0u),
    vec4<u32>(0xaabba1aeu, 0xe59b3f57u, 0u, 0u),
    vec4<u32>(0x5b478fdcu, 0x2a3dd450u, 0u, 0u),
    vec4<u32>(0x7676ed25u, 0xada1f8dcu, 0u, 0u),
    vec4<u32>(0x5509d516u, 0x2711aa8bu, 0u, 0u),
    vec4<u32>(0xc9c92897u, 0x4ae6acd0u, 0u, 0u),
    vec4<u32>(0x5256d67au, 0x56eb3d6bu, 0u, 0u),
    vec4<u32>(0x923bf51eu, 0x1f7a9d55u, 0u, 0u),
    vec4<u32>(0x397a7f68u, 0x3600427du, 0u, 0u),
    vec4<u32>(0x5b72c3d0u, 0xe5076df7u, 0u, 0u),
    vec4<u32>(0x2c6090adu, 0xfcd59aa1u, 0u, 0u),
    vec4<u32>(0x68b57a9eu, 0xcd895e8cu, 0u, 0u),
    vec4<u32>(0xd730ae3eu, 0x41df7ef9u, 0u, 0u),
    vec4<u32>(0x9abe977du, 0xee3e2b88u, 0u, 0u),
    vec4<u32>(0xbeb9c405u, 0xd29bb7edu, 0u, 0u),
    vec4<u32>(0xf608e382u, 0x7d5c08eeu, 0u, 0u),
    vec4<u32>(0xaaf0802cu, 0x89ae889cu, 0u, 0u),
    vec4<u32>(0x6d2af617u, 0xb35a8e97u, 0u, 0u),
    vec4<u32>(0xafaf5173u, 0xdb14234eu, 0u, 0u),
    vec4<u32>(0xd48b1c98u, 0x78f04462u, 0u, 0u),
    vec4<u32>(0xe47ce88au, 0x265293b0u, 0u, 0u),
    vec4<u32>(0x69b9d32fu, 0x999a649bu, 0u, 0u),
    vec4<u32>(0x698e01d3u, 0x64b0a186u, 0u, 0u),
    vec4<u32>(0xdfae8bb8u, 0xee0b22d0u, 0u, 0u),
    vec4<u32>(0xca04a7eeu, 0x4fd53e50u, 0u, 0u),
    vec4<u32>(0x81f25047u, 0x5762bfe1u, 0u, 0u),
    vec4<u32>(0xbeb5e3bdu, 0xf51593e2u, 0u, 0u),
    vec4<u32>(0x60e32477u, 0x1e5e2b57u, 0u, 0u),
    vec4<u32>(0xf9aaaeedu, 0x622462a1u, 0u, 0u),
    vec4<u32>(0xcdb222aeu, 0xaa284b3eu, 0u, 0u),
    vec4<u32>(0x542bf3fcu, 0x63c8e72fu, 0u, 0u),
    vec4<u32>(0xcb43b5e0u, 0x3ba588cau, 0u, 0u),
    vec4<u32>(0xc99150ddu, 0x23eda6f3u, 0u, 0u),
    vec4<u32>(0xbaac9a5au, 0xaad3bea4u, 0u, 0u),
    vec4<u32>(0x9b94184au, 0xe9da8d69u, 0u, 0u),
    vec4<u32>(0xd93e024cu, 0xcdb13f4cu, 0u, 0u),
    vec4<u32>(0x56f655e3u, 0x902cbd09u, 0u, 0u),
    vec4<u32>(0xc759532fu, 0x5b4e40ffu, 0u, 0u),
    vec4<u32>(0xa2357af7u, 0xde795c20u, 0u, 0u),
    vec4<u32>(0xe0ea4c6eu, 0x7b72c539u, 0u, 0u),
    vec4<u32>(0xe2ce9976u, 0x144573dau, 0u, 0u),
    vec4<u32>(0x8f35fc88u, 0x802028b6u, 0u, 0u),
    vec4<u32>(0x2c4fe7c2u, 0x6d36c502u, 0u, 0u),
    vec4<u32>(0xa9b9def3u, 0xa205d0ffu, 0u, 0u),
    vec4<u32>(0x1ea6ba2fu, 0xf6e7e38bu, 0u, 0u),
    vec4<u32>(0xe5258d64u, 0x34f7909au, 0u, 0u),
    vec4<u32>(0x77b97fcau, 0xb0464d9du, 0u, 0u),
    vec4<u32>(0xde7e00a6u, 0x64ddb9d5u, 0u, 0u),
    vec4<u32>(0x27975d97u, 0xed0d75cu, 0u, 0u),
    vec4<u32>(0x1127338bu, 0x1cbb36f1u, 0u, 0u),
    vec4<u32>(0xcfd0b6bau, 0x6673e505u, 0u, 0u),
    vec4<u32>(0x30872e01u, 0x605f9028u, 0u, 0u),
    vec4<u32>(0x7e95fe4fu, 0x3fd5eb92u, 0u, 0u),
    vec4<u32>(0xa24c69cdu, 0xe81025b5u, 0u, 0u),
    vec4<u32>(0xde23f74eu, 0xf7d0ce75u, 0u, 0u),
    vec4<u32>(0xa8585089u, 0xf39942b6u, 0u, 0u),
    vec4<u32>(0xf7b71df6u, 0x6d808a08u, 0u, 0u),
    vec4<u32>(0x88f49a8bu, 0xf8806b65u, 0u, 0u),
    vec4<u32>(0x2a32107au, 0x57df2d8cu, 0u, 0u),
    vec4<u32>(0x4d654a2du, 0x16e7c207u, 0u, 0u),
    vec4<u32>(0xfcf33835u, 0x213de241u, 0u, 0u),
    vec4<u32>(0x5a0976f6u, 0xb0f2b890u, 0u, 0u),
    vec4<u32>(0xbd355417u, 0xd8e3cf2bu, 0u, 0u),
    vec4<u32>(0x79d9330fu, 0xe4986916u, 0u, 0u),
    vec4<u32>(0xa3821b28u, 0x763b45d2u, 0u, 0u),
    vec4<u32>(0xeb0a1f0du, 0x908bf65u, 0u, 0u),
    vec4<u32>(0x194b24f4u, 0x7691eb2du, 0u, 0u),
    vec4<u32>(0x33ae13b2u, 0xe435512u, 0u, 0u),
    vec4<u32>(0xfc2fe76fu, 0x93c393dbu, 0u, 0u),
    vec4<u32>(0x5d48cdeau, 0x98f60748u, 0u, 0u),
    vec4<u32>(0x309819c0u, 0xe3d95f30u, 0u, 0u),
    vec4<u32>(0x3eaf6acfu, 0x1ef581a9u, 0u, 0u),
    vec4<u32>(0xa030fca4u, 0xb24c1b7u, 0u, 0u),
    vec4<u32>(0x5670b327u, 0x624370beu, 0u, 0u),
    vec4<u32>(0x5a11e486u, 0x5f1e2861u, 0u, 0u),
    vec4<u32>(0x909e042bu, 0xfe04051fu, 0u, 0u),
    vec4<u32>(0x47fd3803u, 0x7257e5b1u, 0u, 0u),
    vec4<u32>(0xb82f2e78u, 0xe6ae134bu, 0u, 0u),
    vec4<u32>(0xf4784511u, 0x5711fd5cu, 0u, 0u),
    vec4<u32>(0xc08c0bcu, 0xf83a4266u, 0u, 0u),
    vec4<u32>(0x9a3ce855u, 0x2cd8c96du, 0u, 0u),
    vec4<u32>(0xb0e17271u, 0x7d2ffb1bu, 0u, 0u),
    vec4<u32>(0xcaea3811u, 0x85ae1528u, 0u, 0u),
    vec4<u32>(0xc7adb0b8u, 0x52a345d5u, 0u, 0u),
    vec4<u32>(0xf3faee94u, 0x504c4c51u, 0u, 0u),
    vec4<u32>(0x9cfccaf9u, 0xbce34a64u, 0u, 0u),
    vec4<u32>(0x66fb6dc9u, 0xe0a33892u, 0u, 0u)
  );
@group(0) @binding(0) var<uniform> parametros: Parametros;
@group(0) @binding(1) var<storage, read_write> candidatos: Resultados;
@group(0) @binding(2) var<uniform> constantes: Constantes;

fn sumar32(a: u32, b: u32, acarreo: u32) -> F {
  let parcial = a + b;
  let suma = parcial + acarreo;
  return F(suma, select(0u, 1u, parcial < a) + select(0u, 1u, suma < parcial));
}
fn sumaPequena(a: F, b: F) -> F {
  let bajo = a.x + b.x;
  return F(bajo, a.y + b.y + select(0u, 1u, bajo < a.x));
}
fn restar32(a: u32, b: u32, prestamo: u32) -> F {
  let parcial = a - b;
  let resta = parcial - prestamo;
  return F(resta, select(0u, 1u, parcial > a) + select(0u, 1u, resta > parcial));
}
fn canon(a: F) -> F {
  if (a.y == 0xffffffffu && a.x >= 1u) { return F(a.x - 1u, 0u); }
  return a;
}
fn add(a: F, b: F) -> F {
  let bajo = sumar32(a.x, b.x, 0u);
  let alto = sumar32(a.y, b.y, bajo.y);
  var r = F(bajo.x, alto.x);
  if (alto.y != 0u) {
    let ajuste = sumar32(r.x, 0xffffffffu, 0u);
    
  r = F(ajuste.x, r.y + ajuste.y);
  }
  return canon(r);
}
fn mul32(a: u32, b: u32) -> F {
  
  let a0 = a & 0xffffu;
  let a1 = a >> 16u;
  let b0 = b & 0xffffu;
  let b1 = b >> 16u;
  let p0 = a0 * b0;
  let p1 = a1 * b0;
  let p2 = a0 * b1;
  let p3 = a1 * b1;
  let medio = p1 + p2;
  let acarreoMedio = select(0u, 1u, medio < p1);
  let bajo = p0 + (medio << 16u);
  return F(bajo, p3 + (medio >> 16u) + (acarreoMedio << 16u) + select(0u, 1u, bajo < p0));
}
fn productoAncho(p0: F, p1: F, p2: F, p3: F) -> vec4<u32> {
  let a = sumar32(p0.y, p1.x, 0u);
  let b = sumar32(a.x, p2.x, 0u);
  let c = sumar32(p1.y, p2.y, a.y + b.y);
  let d = sumar32(c.x, p3.x, 0u);
  return vec4<u32>(p0.x, b.x, d.x, p3.y + c.y + d.y);
}

fn multiplicarAncho(a: F, b: F) -> vec4<u32> {
  
  return productoAncho(mul32(a.x, b.x), mul32(a.x, b.y), mul32(a.y, b.x), mul32(a.y, b.y));
}
fn reducirProducto(a: vec4<u32>) -> F {
  let bajo = restar32(a.x, a.w, 0u);
  let alto = restar32(a.y, 0u, bajo.y);
  var r = F(bajo.x, alto.x);
  if (alto.y != 0u) {
    let ajusteBajo = restar32(r.x, 0xffffffffu, 0u);
    let ajusteAlto = restar32(r.y, 0u, ajusteBajo.y);
    r = F(ajusteBajo.x, ajusteAlto.x);
  }
  let termino = F(0u - a.z, a.z - select(0u, 1u, a.z != 0u));
  return add(canon(r), termino);
}
fn mul(a: F, b: F) -> F {
  return reducirProducto(multiplicarAncho(a, b));
}
fn cuadrado(a: F) -> F {
  let cruzado = mul32(a.x, a.y);
  return reducirProducto(productoAncho(mul32(a.x, a.x), cruzado, cruzado, mul32(a.y, a.y)));
}
fn productoMasSuma(a: F, b: F, suma: F) -> F {
  let p = multiplicarAncho(a, b);
  let x = sumar32(p.x, suma.x, 0u);
  let y = sumar32(p.y, suma.y, x.y);
  let z = sumar32(p.z, 0u, y.y);
  return reducirProducto(vec4<u32>(x.x, y.x, z.x, p.w + z.y));
}
fn sbox(a: F) -> F {
  let a2 = cuadrado(a);
  let a4 = cuadrado(a2);
  return mul(mul(a4, a2), a);
}
fn acc(a: F) -> Acc { return Acc(a.x, a.y, 0u); }
fn acumular(a: Acc, b: F) -> Acc {
  let x = sumar32(a.bajo, b.x, 0u);
  let y = sumar32(a.alto, b.y, x.y);
  return Acc(x.x, y.x, a.acarreo + y.y);
}
fn juntar(a: Acc, b: Acc) -> Acc {
  let x = sumar32(a.bajo, b.bajo, 0u);
  let y = sumar32(a.alto, b.alto, x.y);
  return Acc(x.x, y.x, a.acarreo + b.acarreo + y.y);
}
fn reducirSuma(a: Acc) -> F {
  let r = canon(F(a.bajo, a.alto));
  if (a.acarreo == 0u) { return r; }
  return add(r, F(0u - a.acarreo, a.acarreo - 1u));
}
fn externa(s: ptr<function, array<F, 12>>) {
  
  let a0 = (*s)[0];
  let b0 = (*s)[1];
  let c0 = (*s)[2];
  let d0 = (*s)[3];
  let ab0 = acumular(acc(a0), b0);
  let cd0 = acumular(acc(c0), d0);
  let total0 = juntar(ab0, cd0);
  let masB0 = acumular(total0, b0);
  let masD0 = acumular(total0, d0);
  let y0 = juntar(masB0, ab0);
  let y1 = acumular(acumular(masB0, c0), c0);
  let y2 = juntar(masD0, cd0);
  let y3 = acumular(acumular(masD0, a0), a0);


  let a4 = (*s)[4];
  let b4 = (*s)[5];
  let c4 = (*s)[6];
  let d4 = (*s)[7];
  let ab4 = acumular(acc(a4), b4);
  let cd4 = acumular(acc(c4), d4);
  let total4 = juntar(ab4, cd4);
  let masB4 = acumular(total4, b4);
  let masD4 = acumular(total4, d4);
  let y4 = juntar(masB4, ab4);
  let y5 = acumular(acumular(masB4, c4), c4);
  let y6 = juntar(masD4, cd4);
  let y7 = acumular(acumular(masD4, a4), a4);


  let a8 = (*s)[8];
  let b8 = (*s)[9];
  let c8 = (*s)[10];
  let d8 = (*s)[11];
  let ab8 = acumular(acc(a8), b8);
  let cd8 = acumular(acc(c8), d8);
  let total8 = juntar(ab8, cd8);
  let masB8 = acumular(total8, b8);
  let masD8 = acumular(total8, d8);
  let y8 = juntar(masB8, ab8);
  let y9 = acumular(acumular(masB8, c8), c8);
  let y10 = juntar(masD8, cd8);
  let y11 = acumular(acumular(masD8, a8), a8);

  
  let suma0 = juntar(juntar(y0, y4), y8);


  let suma1 = juntar(juntar(y1, y5), y9);


  let suma2 = juntar(juntar(y2, y6), y10);


  let suma3 = juntar(juntar(y3, y7), y11);

  (*s)[0] = reducirSuma(juntar(y0, suma0));
(*s)[1] = reducirSuma(juntar(y1, suma1));
(*s)[2] = reducirSuma(juntar(y2, suma2));
(*s)[3] = reducirSuma(juntar(y3, suma3));
(*s)[4] = reducirSuma(juntar(y4, suma0));
(*s)[5] = reducirSuma(juntar(y5, suma1));
(*s)[6] = reducirSuma(juntar(y6, suma2));
(*s)[7] = reducirSuma(juntar(y7, suma3));
(*s)[8] = reducirSuma(juntar(y8, suma0));
(*s)[9] = reducirSuma(juntar(y9, suma1));
(*s)[10] = reducirSuma(juntar(y10, suma2));
(*s)[11] = reducirSuma(juntar(y11, suma3));
}
fn internas(s: ptr<function, array<F, 12>>) {
  for (var ronda = 0u; ronda < 22u; ronda++) { {
    (*s)[0] = sbox(add((*s)[0], constantesFijas[ronda].xy));
    var suma = acc((*s)[0]);
    suma = acumular(suma, (*s)[1]);
suma = acumular(suma, (*s)[2]);
suma = acumular(suma, (*s)[3]);
suma = acumular(suma, (*s)[4]);
suma = acumular(suma, (*s)[5]);
suma = acumular(suma, (*s)[6]);
suma = acumular(suma, (*s)[7]);
suma = acumular(suma, (*s)[8]);
suma = acumular(suma, (*s)[9]);
suma = acumular(suma, (*s)[10]);
suma = acumular(suma, (*s)[11]);
    let total = reducirSuma(suma);
    (*s)[0] = productoMasSuma((*s)[0], F(0x23ba9300u, 0xc3b6c08eu), total);
(*s)[1] = productoMasSuma((*s)[1], F(0x4a324fb6u, 0xd84b5de9u), total);
(*s)[2] = productoMasSuma((*s)[2], F(0x5b35b84fu, 0xd0c371cu), total);
(*s)[3] = productoMasSuma((*s)[3], F(0xe7188037u, 0x7964f570u), total);
(*s)[4] = productoMasSuma((*s)[4], F(0xd996604bu, 0x5daf18bbu), total);
(*s)[5] = productoMasSuma((*s)[5], F(0xb9595257u, 0x6743bc47u), total);
(*s)[6] = productoMasSuma((*s)[6], F(0x2c59bb70u, 0x5528b936u), total);
(*s)[7] = productoMasSuma((*s)[7], F(0x7127b68bu, 0xac45e25bu), total);
(*s)[8] = productoMasSuma((*s)[8], F(0xfbb606b5u, 0xa2077d7du), total);
(*s)[9] = productoMasSuma((*s)[9], F(0xaee378aeu, 0xf3faac6fu), total);
(*s)[10] = productoMasSuma((*s)[10], F(0x1545e883u, 0xc6388b5u), total);
(*s)[11] = productoMasSuma((*s)[11], F(0x44917b60u, 0xd27dbb69u), total);
  } }
}
fn terminales(s: ptr<function, array<F, 12>>) {
  for (var ronda = 0u; ronda < 4u; ronda++) {
    (*s)[0] = sbox(add((*s)[0], constantesFijas[70u + ronda * 12u + 0u].xy));
(*s)[1] = sbox(add((*s)[1], constantesFijas[70u + ronda * 12u + 1u].xy));
(*s)[2] = sbox(add((*s)[2], constantesFijas[70u + ronda * 12u + 2u].xy));
(*s)[3] = sbox(add((*s)[3], constantesFijas[70u + ronda * 12u + 3u].xy));
(*s)[4] = sbox(add((*s)[4], constantesFijas[70u + ronda * 12u + 4u].xy));
(*s)[5] = sbox(add((*s)[5], constantesFijas[70u + ronda * 12u + 5u].xy));
(*s)[6] = sbox(add((*s)[6], constantesFijas[70u + ronda * 12u + 6u].xy));
(*s)[7] = sbox(add((*s)[7], constantesFijas[70u + ronda * 12u + 7u].xy));
(*s)[8] = sbox(add((*s)[8], constantesFijas[70u + ronda * 12u + 8u].xy));
(*s)[9] = sbox(add((*s)[9], constantesFijas[70u + ronda * 12u + 9u].xy));
(*s)[10] = sbox(add((*s)[10], constantesFijas[70u + ronda * 12u + 10u].xy));
(*s)[11] = sbox(add((*s)[11], constantesFijas[70u + ronda * 12u + 11u].xy));
    externa(s);
  }
}
fn permutar(s: ptr<function, array<F, 12>>) {
  externa(s);
  for (var ronda = 0u; ronda < 4u; ronda++) {
    (*s)[0] = sbox(add((*s)[0], constantesFijas[22u + ronda * 12u + 0u].xy));
(*s)[1] = sbox(add((*s)[1], constantesFijas[22u + ronda * 12u + 1u].xy));
(*s)[2] = sbox(add((*s)[2], constantesFijas[22u + ronda * 12u + 2u].xy));
(*s)[3] = sbox(add((*s)[3], constantesFijas[22u + ronda * 12u + 3u].xy));
(*s)[4] = sbox(add((*s)[4], constantesFijas[22u + ronda * 12u + 4u].xy));
(*s)[5] = sbox(add((*s)[5], constantesFijas[22u + ronda * 12u + 5u].xy));
(*s)[6] = sbox(add((*s)[6], constantesFijas[22u + ronda * 12u + 6u].xy));
(*s)[7] = sbox(add((*s)[7], constantesFijas[22u + ronda * 12u + 7u].xy));
(*s)[8] = sbox(add((*s)[8], constantesFijas[22u + ronda * 12u + 8u].xy));
(*s)[9] = sbox(add((*s)[9], constantesFijas[22u + ronda * 12u + 9u].xy));
(*s)[10] = sbox(add((*s)[10], constantesFijas[22u + ronda * 12u + 10u].xy));
(*s)[11] = sbox(add((*s)[11], constantesFijas[22u + ronda * 12u + 11u].xy));
    externa(s);
  }
  internas(s);
  terminales(s);
}
fn desdePreestado(s: ptr<function, array<F, 12>>) {
  (*s)[0] = sbox((*s)[0]);
(*s)[1] = sbox((*s)[1]);
(*s)[2] = sbox((*s)[2]);
(*s)[3] = sbox((*s)[3]);
(*s)[4] = sbox((*s)[4]);
(*s)[5] = sbox((*s)[5]);
(*s)[6] = sbox((*s)[6]);
(*s)[7] = sbox((*s)[7]);
(*s)[8] = sbox((*s)[8]);
(*s)[9] = sbox((*s)[9]);
(*s)[10] = sbox((*s)[10]);
(*s)[11] = sbox((*s)[11]);
  externa(s);
  for (var ronda = 1u; ronda < 4u; ronda++) {
    (*s)[0] = sbox(add((*s)[0], constantesFijas[22u + ronda * 12u + 0u].xy));
(*s)[1] = sbox(add((*s)[1], constantesFijas[22u + ronda * 12u + 1u].xy));
(*s)[2] = sbox(add((*s)[2], constantesFijas[22u + ronda * 12u + 2u].xy));
(*s)[3] = sbox(add((*s)[3], constantesFijas[22u + ronda * 12u + 3u].xy));
(*s)[4] = sbox(add((*s)[4], constantesFijas[22u + ronda * 12u + 4u].xy));
(*s)[5] = sbox(add((*s)[5], constantesFijas[22u + ronda * 12u + 5u].xy));
(*s)[6] = sbox(add((*s)[6], constantesFijas[22u + ronda * 12u + 6u].xy));
(*s)[7] = sbox(add((*s)[7], constantesFijas[22u + ronda * 12u + 7u].xy));
(*s)[8] = sbox(add((*s)[8], constantesFijas[22u + ronda * 12u + 8u].xy));
(*s)[9] = sbox(add((*s)[9], constantesFijas[22u + ronda * 12u + 9u].xy));
(*s)[10] = sbox(add((*s)[10], constantesFijas[22u + ronda * 12u + 10u].xy));
(*s)[11] = sbox(add((*s)[11], constantesFijas[22u + ronda * 12u + 11u].xy));
    externa(s);
  }
  internas(s);
  terminales(s);
}
fn invertir32(a: u32) -> u32 {
  return ((a & 0xffu) << 24u) | ((a & 0xff00u) << 8u) | ((a >> 8u) & 0xff00u) | (a >> 24u);
}
fn candidato(s: ptr<function, array<F, 12>>) -> bool {
  // La representación p..2^64-1 equivale a 0..2^32-2 y se normaliza antes del target.
  
  
  let h0 = invertir32((*s)[0].x);
  let t0 = parametros.objetivo[0][0];
  if (h0 != t0) { return h0 < t0; }

  let h1 = invertir32((*s)[0].y);
  let t1 = parametros.objetivo[0][1];
  if (h1 != t1) { return h1 < t1; }

  let h2 = invertir32((*s)[1].x);
  let t2 = parametros.objetivo[0][2];
  if (h2 != t2) { return h2 < t2; }

  let h3 = invertir32((*s)[1].y);
  let t3 = parametros.objetivo[0][3];
  if (h3 != t3) { return h3 < t3; }

  let h4 = invertir32((*s)[2].x);
  let t4 = parametros.objetivo[1][0];
  if (h4 != t4) { return h4 < t4; }

  let h5 = invertir32((*s)[2].y);
  let t5 = parametros.objetivo[1][1];
  if (h5 != t5) { return h5 < t5; }

  let h6 = invertir32((*s)[3].x);
  let t6 = parametros.objetivo[1][2];
  if (h6 != t6) { return h6 < t6; }

  let h7 = invertir32((*s)[3].y);
  let t7 = parametros.objetivo[1][3];
  if (h7 != t7) { return h7 < t7; }
  return true;
}
@compute @workgroup_size(256)
fn minar(@builtin(global_invocation_id) globalId: vec3<u32>) {
  let base = globalId.x * 2u;
  for (var j = 0u; j < 2u; j++) {
    let indice = base + j;
    if (indice >= parametros.lote.z) { break; }
    let bajo = parametros.lote.x + indice;
    let alto = parametros.lote.y + select(0u, 1u, bajo < parametros.lote.x);
    let x6 = invertir32(alto);
    let x7 = invertir32(bajo);
    let a = F(x6, 0u);
    let b = F(x7, 0u);
    let a2 = sumaPequena(a, a);
    let a3 = sumaPequena(a2, a);
    let a4 = sumaPequena(a2, a2);
    let a6 = sumaPequena(a3, a3);
    let b2 = sumaPequena(b, b);
    let b3 = sumaPequena(b2, b);
    let b4 = sumaPequena(b2, b2);
    let b6 = sumaPequena(b3, b3);
    let c0 = sumaPequena(a, b);
    let c1 = sumaPequena(a3, b);
    let c2 = sumaPequena(a2, b3);
    let c3 = sumaPequena(a, b2);
    let c4 = sumaPequena(a2, b2);
    let c5 = sumaPequena(a6, b2);
    let c6 = sumaPequena(a4, b6);
    let c7 = sumaPequena(a2, b4);
    var s: array<F, 12>;
    s[0] = add(parametros.preestado[0].xy, c0);
s[1] = add(parametros.preestado[1].xy, c1);
s[2] = add(parametros.preestado[2].xy, c2);
s[3] = add(parametros.preestado[3].xy, c3);
s[4] = add(parametros.preestado[4].xy, c4);
s[5] = add(parametros.preestado[5].xy, c5);
s[6] = add(parametros.preestado[6].xy, c6);
s[7] = add(parametros.preestado[7].xy, c7);
s[8] = add(parametros.preestado[8].xy, c0);
s[9] = add(parametros.preestado[9].xy, c1);
s[10] = add(parametros.preestado[10].xy, c2);
s[11] = add(parametros.preestado[11].xy, c3);
    desdePreestado(&s);
    s[0] = add(s[0], F(1u, 0u));
    s[1] = add(s[1], F(1u, 0u));
    permutar(&s);
    if (candidato(&s)) {
      let posicion = atomicAdd(&candidatos.cuenta, 1u);
      if (posicion < 256u) { candidatos.indices[posicion] = indice; }
    }
  }
}

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

//
// Kino/Bokeh - Depth of field effect
//
// Copyright (C) 2016 Unity Technologies
// Copyright (C) 2015 Keijiro Takahashi
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#include "UnityCG.cginc"

// sampler2D _MainTex;
// float4 _MainTex_ST;
// float4 _MainTex_TexelSize;

// シェーダー内部で使用する変数(プロパティから直接，プロパティから計算するもの，計算結果保持用)をここで定義しておく
// プロパティから取り込むパラメータ
float _EnableRadius;
int _IsAF;
float _ManualFocusDistance;
float _FNumber;
int _IsCameraFOV;
float _CameraFOV;
float _FocalLength;
int _IsDebug;
// 以下KinoBokehで使用する変数
// 色情報に使う_MainTex
sampler2D _MainTex;
float4 _MainTex_ST;
float4 _MainTex_TexelSize;
// ブラーかけた結果に使う_BlurTex
sampler2D _BlurTex;
float4 _BlurTex_TexelSize;
// 深度情報に使う_AltCameraDepthTexture
sampler2D _AltCameraDepthTexture;
// カメラパラメータ
float _Distance;
float _LensCoeff;
float _RcpAspect;
float _MaxCoC;
float _RcpMaxCoC;
float _CameraDepthRate;


struct appdata
{
    float4 vertex : POSITION;
    half2 texcoord : TEXCOORD0;
    // UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    float4 pos : SV_POSITION;
    half2 uv : TEXCOORD0;
    half2 uvAlt : TEXCOORD1;
};

// Common vertex shader with single pass stereo rendering support
v2f vert(appdata v)
{
    half2 uvAlt = v.texcoord;
#if UNITY_UV_STARTS_AT_TOP
    if (_MainTex_TexelSize.y < 0.0) uvAlt.y = 1 - uvAlt.y;
#endif

    v2f o;
#if defined(UNITY_SINGLE_PASS_STEREO)
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = UnityStereoScreenSpaceUVAdjust(v.texcoord, _MainTex_ST);
    o.uvAlt = UnityStereoScreenSpaceUVAdjust(uvAlt, _MainTex_ST);
#else
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.texcoord;
    o.uvAlt = uvAlt;
#endif

    // アスペクト比を取り込んでuvを補正
    float rate = 16.0/9.0 * _ScreenParams.y/_ScreenParams.x;
    o.uv.y *= rate;
    o.uvAlt.y *= rate;
    
    // 距離判定と自分の環境の判定　「ある距離より遠い・ある位置より下・自分の環境外なら描画しない」を実現する
    // RTのアルファ，カメラ位置を判別し，posを0に書き換える
    float ownerAlpha = tex2Dlod(_MainTex, float4(0.5,0.5,0,0)).a;
    float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
    if(ownerAlpha < 0.5 ||  distance(_WorldSpaceCameraPos.xyz, worldPos) > _EnableRadius || _WorldSpaceCameraPos.y - worldPos.y > 0.0){
        o.pos = 0;
    } else {
        o.pos = float4(v.texcoord.x*2-1 , 1-v.texcoord.y*2 , 0 , 1);
    }

    return o;
}

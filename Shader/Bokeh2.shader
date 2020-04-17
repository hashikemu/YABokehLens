// --------------------------------------
// yet another virtual lens plus shader
// 2020-04-15 written by karuua
// 色と深度2枚のレンダーテクスチャを受け取り，KinoBokehを使用してボケた画像を生成
// 視界ジャックを使用して一定距離内にあるカメラの視界全体にボケた画像を投影する
// 主な変更点
// ・KinoBokehのBlitをgrabpassで代用
// ・プロパティにパラメータを用意，パラメータ計算をsetparam.cgincに移植
// ・vertexシェーダーをジャック用に書き換え
// ・デバッグ表示をifで切り替える
// --------------------------------------
Shader "orangetailExp/Bokeh2"
{
    Properties
    {
		// 外部から取り込むレンダーテクスチャ
		[NoScaleOffset] _MainTex("ColorのRT", 2D) = ""{}
		[NoScaleOffset] _AltCameraDepthTexture("DepthのRT", 2D) = ""{}
		// 設定パラメータ
		_EnableRadius("ジャックする半径[m]", Range(0.0,1.0))=0.35
        [Space]
        // カメラ関連のパラメータ
		[MaterialToggle] _IsAF("オートフォーカス", Int) = 0
		_ManualFocusDistance("手動でフォーカスを合わせる距離[m]",  Range(0.0,5.0)) = 3.0
		_FNumber("Aperture", Float) = 0.5
        [Space]
		[MaterialToggle] _IsCameraFOV("FOVから焦点距離を決定するか", Int) = 0
		_CameraFOV("カメラのFOV[deg]",Float) = 30
        _FocalLength("焦点距離[mm]",Float) = 45
        [MaterialToggle] _IsDebug("デバッグ表示", Int) = 0
    }

    Subshader
    {
        // タグと基本レンダリング設定
		Tags { "RenderType" = "Transparent+2001" "Queue" = "Transparent+2001"}
		LOD 100 Cull Off ZWrite Off ZTest Off

        // 1パス _MainTexに事前フィルターをかける
        Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag_Prefilter
            #pragma multi_compile _ UNITY_COLORSPACE_GAMMA
            #define PREFILTER_LUMA_WEIGHT
            #include "Prefilter.cginc"
            ENDCG
        }

		// Grabパス 事前フィルターをかけたものを_MainTexにgrabする
		GrabPass { "_Main1Tex" }

        // 2パス _Main1Texにボケフィルターをかける
        Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag_Blur
            #define KERNEL_LARGE
            #include "DiskBlur.cginc"
            ENDCG
        }

		// Grabパス ボケフィルターをかけたものを_MainTexにgrabする
		GrabPass { "_Main2Tex" }

        // 3パス _Main2Texにブラーをかける
        Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag_Blur2
            #include "Composition.cginc"
            ENDCG
        }

		// Grabパス ブラーをかけたものを_BlurTexにgrabする
		GrabPass { "_BlurTex" }

		// 4パス _MainTexと_BlurTexをcompositionする
        Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma multi_compile _ UNITY_COLORSPACE_GAMMA
            #pragma fragment frag_Composition
            #include "Composition.cginc"
            ENDCG
        }

        // 5パス デバッグ表示
        Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag_CoC
            #include "Debug.cginc"
            ENDCG
        }
    }
}

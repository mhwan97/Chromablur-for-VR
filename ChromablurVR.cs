using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(ChromablurVRRenderer), PostProcessEvent.BeforeTransparent, "Custom/ChromablurVR")]
public sealed class ChromablurVR : PostProcessEffectSettings
{
    [Range(0f, 0.1f), Tooltip("Blur size")]
    public FloatParameter blurSize = new FloatParameter { value = 0f };

    [Range(1, 4), Tooltip("Blur Mode")]
    public IntParameter mode = new IntParameter { value = 0 };

    [Range(0, 2), Tooltip("RGB Channel")]
    public IntParameter rgb = new IntParameter { value = 0 };
}

public sealed class ChromablurVRRenderer : PostProcessEffectRenderer<ChromablurVR>
{
    public override DepthTextureMode GetCameraFlags()
    {
        return DepthTextureMode.Depth;
    }

    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/Custom/ChromablurVR"));

        if (settings.mode == 1) // Gaussian blur mode
        {
            sheet.properties.SetFloat("_BlurSize", settings.blurSize);
            var buffer1 = context.GetScreenSpaceTemporaryRT();
            context.command.BlitFullscreenTriangle(context.source, buffer1, sheet, 0);
            context.command.BlitFullscreenTriangle(buffer1, context.destination, sheet, 1);
            RenderTexture.ReleaseTemporary(buffer1);
        }

        else if (settings.mode == 2) //Disk blur full screen
        {
            sheet.properties.SetFloat("BlurSize", settings.blurSize);
            sheet.properties.SetInt("_RGB", settings.rgb);
            sheet.properties.SetInt("_DiskFlag", 1);
            context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 2);
        }

        else if (settings.mode == 3) //Disk blur depth bin
        {
            sheet.properties.SetFloat("BlurSize", settings.blurSize);
            sheet.properties.SetInt("_RGB", settings.rgb);
            sheet.properties.SetInt("_DiskFlag", 2);
            context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 2);
        }

        else if (settings.mode == 4) //Disk blur depth scaling
        {
            sheet.properties.SetFloat("BlurSize", settings.blurSize);
            sheet.properties.SetInt("_RGB", settings.rgb);
            sheet.properties.SetInt("_DiskFlag", 3);
            context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 2);
        }
    }
}
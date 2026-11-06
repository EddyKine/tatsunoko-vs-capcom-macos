/*
 TvC CRT Pixel-Locked Strong
 Dolphin/ModernGekko single-pass post-processing shader.

 Same pixel-locked cadence as the Soft profile, with a darker single scanline.
 The line remains one physical output pixel wide even on high-DPI displays.
*/

void main()
{
    float4 color = Sample();
    float2 uv = GetCoordinates();
    float2 output_size = GetWindowResolution();

    float period = max(floor(output_size.y / 480.0 + 0.5), 2.0);
    float pixel_y = floor(uv.y * output_size.y);
    float row = mod(pixel_y, period);

    float dark_row = 1.0 - step(1.0, row);
    float scan = mix(1.028, 0.72, dark_row);

    color.rgb = min(color.rgb * scan, float3(1.0, 1.0, 1.0));
    SetOutput(color);
}

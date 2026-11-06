/*
 TvC CRT Pixel-Locked Soft
 Dolphin/ModernGekko single-pass post-processing shader.

 v0.3.2: pixel-locked scanlines.
 Instead of drawing exactly 480 UV-space bands (which aliases whenever the
 output height is not an integer multiple of 480), this shader chooses the
 nearest integer pixel period and darkens exactly ONE physical output row per
 period. This removes the 2-lines-then-gap beat pattern on 1080p/1440p/4K/5K.
*/

void main()
{
    float4 color = Sample();
    float2 uv = GetCoordinates();
    float2 output_size = GetWindowResolution();

    // Nearest integer number of output pixels per nominal 480p source row.
    // 1080p -> 2, 1440p -> 3, 2160p -> 5, 2880p -> 6.
    float period = max(floor(output_size.y / 480.0 + 0.5), 2.0);

    // Lock the pattern to real output pixel rows. No fractional UV cadence.
    float pixel_y = floor(uv.y * output_size.y);
    float row = mod(pixel_y, period);

    // Exactly one dim row per period. Bright rows get a tiny compensation so
    // the image does not look globally darker.
    float dark_row = 1.0 - step(1.0, row);
    float scan = mix(1.018, 0.86, dark_row);

    color.rgb = min(color.rgb * scan, float3(1.0, 1.0, 1.0));
    SetOutput(color);
}

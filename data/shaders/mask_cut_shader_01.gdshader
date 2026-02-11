shader_type canvas_item;

uniform sampler2D mask_texture : source_color, filter_nearest, repeat_disable;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 mask_pixel_size = vec2(100.0, 100.0); // Desired mask size in screen pixels

void fragment() {
    vec4 sprite_color = texture(TEXTURE, UV);
    
    // Get screen pixel size
    vec2 screen_pixel = SCREEN_PIXEL_SIZE;
    
    // Convert UV to screen coordinates
    vec2 screen_uv = SCREEN_UV;
    
    // Calculate mask UV based on desired pixel size
    // This makes the mask a consistent screen size regardless of sprite
    vec2 mask_uv = UV;
    
    // Adjust for sprite texture size vs screen size
    vec2 sprite_texel = 1.0 / vec2(textureSize(TEXTURE, 0));
    vec2 scale_factor = sprite_texel / screen_pixel;
    
    // Scale UV to make mask consistent size
    mask_uv = (UV - 0.5) * (vec2(1.0) / (mask_pixel_size * screen_pixel * scale_factor)) + 0.5;
    
    vec4 mask_color = texture(mask_texture, mask_uv);
    
    // Calculate base alpha from original sprite
    float original_alpha = sprite_color.a;
    
    // Calculate masked alpha (full transparency if mask is 0)
    float masked_alpha = sprite_color.a * mask_color.a;
    
    // Mix between original and masked based on progress
    float base_alpha = mix(original_alpha, masked_alpha, progress);
    
    // Calculate fade factor: when progress is 1.0, fade to 0.5 alpha
    // This interpolates from 1.0 (full alpha) to 0.5 (half alpha) as progress goes to 1.0
    float fade_factor = mix(1.0, 0.5, progress);
    
    // Apply the fade factor to the base alpha
    float final_alpha = base_alpha * fade_factor;
    
    COLOR = vec4(sprite_color.rgb, final_alpha);
}
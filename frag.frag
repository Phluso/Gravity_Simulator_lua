uniform vec3 lightPos[10];
uniform vec3 lightColor[10];

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords){
    vec4 texturecolor = Texel(tex, texture_coords);

    for (int i = 0; i < 10; i ++){
        float lightIntensity = smoothstep(lightPos[i].z, .0, distance(vec2(screen_coords), vec2(
            lightPos[i].x, 
            lightPos[i].y
        )));

        color = vec4(vec3(lightColor[i].rgb), 1);
        texturecolor = mix(texturecolor, color, lightIntensity);
    }

    return vec4(vec3(0), 1) + texturecolor;
}
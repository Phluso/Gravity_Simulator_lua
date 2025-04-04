

uniform vec4 objPos[100];
/*
bool inCamera(vec2 pos, vec2 camSpace){
    return (pos.x >= camSpace)
}
*/

uniform vec2 resolution;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords){
    vec4 texturecolor = Texel(tex, texture_coords);
    vec4 corBase = vec4(0, 0, 0, 1);

    vec2 pos = vec2(gl_FragCoord.xy / resolution.xy);

    for (int i = 0; i < 100; i ++){

    
        float size = objPos[i].z;
        vec4 bola = vec4(vec3(step(distance(vec2(screen_coords - screen_coords/texture_coords/2), vec2(objPos[i].xy)), size)), 1);
        texturecolor += bola;
        //texturecolor.r = step(.5, pos.x);
    }



    return corBase + texturecolor;
}
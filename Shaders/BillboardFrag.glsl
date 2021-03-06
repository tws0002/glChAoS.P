////////////////////////////////////////////////////////////////////////////////
//
//  Copyright (c) 2018 Michele Morrone
//  All rights reserved.
//
//  mailto:me@michelemorrone.eu
//  mailto:brutpitt@gmail.com
//  
//  https://github.com/BrutPitt
//
//  https://michelemorrone.eu
//  https://BrutPitt.com
//
//  This software is distributed under the terms of the BSD 2-Clause license:
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//      * Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//   
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF 
//  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
////////////////////////////////////////////////////////////////////////////////

// #version dynamically inserted

layout(std140) uniform;

LAYUOT_BINDING(1) uniform sampler2D tex;

subroutine vec4 _pixelColor();


LAYUOT_BINDING(2) uniform _particlesData {
    float lightDiffInt;
    float lightSpecInt;
    float lightAmbInt ;
    float lightShinExp;
    vec3 lightDir;
    float sstepColorMin;
    float sstepColorMax;
    float pointSize;
    float pointDistAtten;
    float alphaDistAtten;
    float alphaSkip;
    float alphaK;
    float clippingDist;
    float zFar;
    float velIntensity;
} u;


//in vec4 geomPos;
in vec4 LightRay; 
in vec3 posEye;

in float pointSZ;
in vec2 texCoord;

in vec4 geomParticleColor;
in float ptDist;


out vec4 outColor;

float getAlpha(float alpha)
{

    CONST float alphaAtten = exp(-0.1*pow(ptDist+1.f, u.alphaDistAtten*.1));
    return clamp(alpha*alpha * alphaAtten * u.alphaK, 0.0, 1.0);

}



LAYUOT_INDEX(1) subroutine(_pixelColor) vec4 pixelColorLight()
{
    vec3 N;

    //vec3 light = 
    CONST float texVal = texture(tex, texCoord).r;
    vec4 color = geomParticleColor * texVal;

    float alpha = getAlpha(color.a);

    N = vec3((texCoord - vec2(.5)), texVal); // xy = radius in 0, z = magnitudo
    //N.z = texVal;   //Using texIntensityVal, sastest, instead: N.z = sqrt(1.0-mag);

    float mag = dot(N.xy, N.xy);
    if (mag > .25 || alpha < u.alphaSkip) discard;   // kill pixels outside circle: r=.5
    
    N = normalize(N);
    
    //float val = ;    
    float diffuse = max(0.0, dot((LightRay.xyz), N)); //LightRay.xyz normalized in VS
    

    //float alpha = smoothstep(0.0, .9, color.a*color.a);


// point on surface of sphere in eye space
    vec3 spherePosEye =  N*pointSZ;  //N*radius

//    gl_FragColor = gl_Color * diffuse;

	vec3 v = normalize(spherePosEye);
    vec3 h = normalize(LightRay.xyz + v);
    float specular = pow(max(0.0, dot(N,h)), u.lightShinExp);

    vec3 lColor =  smoothstep(u.sstepColorMin, u.sstepColorMax,
                                (color.rgb * diffuse *u.lightDiffInt + 
                                vec3(specular) *u.lightSpecInt     + 
                                (color.rgb+u.lightAmbInt*0.1) * u.lightAmbInt)); /*+ color.rgb * (1.0 - negDiffuse)+ color.rgb * ambient + vec3(specular) * .6*/

//    vec3 delta = fwidth(diffuse);
//    lColor = mix(lColor, vec3(.0), delta);

    //vec3 lColor = color.rgb * diffuse *.33 + color.rgb * (1.0 - diffuse) * .2 + ambient + vec3(specular) * .6;
    //color.rgb = mix(lColor, color.rgb, alpha*alpha);

    //outColor = vec4(lColor, 1.0);

//MUST go on vtx
    //float distAtten = 1.f/(pointDistance*pointDistance);
    //float maxDistance = distance(vec3( 0.f, 0.f, 3.f),vec3( 0.f, 0.f, -3.f));
    //float distAtten = (1.f/(maxDistance)) * 1.3; 

    //gl_FragColor = vec4(color.rgb , min(1.f,(specular+color.a)*.7)) ; //*1.f/(pointDistance)
    
    //gl_FragColor = vec4(color.rgb , color.a) ;
    //vec4 col = vec4(lColor.rgb , alpha*alphaK*(clamp(alphaAtten, 0.0, 1.7))); 

    vec4 col = vec4(lColor.rgb , alpha * diffuse *u.lightDiffInt);

    
    //float alphaAtten = (color.a)/(pow(length(posEye),distAlphaFactor));
    //gl_FragColor = vec4(color.rgb , min(color.a*alphaK,alphaAtten)); 
     return  col;        
}

LAYUOT_INDEX(0) subroutine(_pixelColor) vec4 pixelColorOnly()
{
    vec4 color = geomParticleColor * texture(tex, texCoord).r;
    //color = color + mix(vec4(0.0, 0.0, 0.0, alpha), vec4(.7, .7, .7, alpha), alpha);
    //color.rgb = color.rgb + mix(vec3(0.0, 0.0, 0.0), vec3(.5, .5, .5), alpha*alpha);
    //color.rgb = mix(color.rgb, vec3(1.0, 1.0, 1.0), alpha);

    float alpha = getAlpha(color.a);
    //if(alpha < u.alphaSkip ) discard ;

    return vec4(color.rgb , alpha); 

}

subroutine uniform _pixelColor pixelColor;

void main(void)
{

    gl_FragDepth = -posEye.z*u.zFar;
    outColor = pixelColor();
}

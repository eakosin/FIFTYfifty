// FIFTYfifty - Space shooter using a probability mechanic.
// Copyright (C) 2014  Evan A. Kosin

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

extern vec2 love_ScreenSize; // Size of the screen in pixels
extern float amount; // Mix amount for blur or fade
extern float fade; // Whether to mix between cinematicSample and blurSample or blurSample and color
varying vec4 vpos; // Unused vertex position

#ifdef VERTEX
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
    vpos = vertex_position;
    return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL

// 5x5 Gaussian kernel with radius of 3
const float simpleGaussianKernel[25] = float[25]( 
0.01905031014488527, 0.03140865154930652, 0.03710493756184187, 0.03140865154930652, 0.01905031014488527, 
0.03140865154930652, 0.05178411189334978, 0.06117569980620832, 0.05178411189334978, 0.03140865154930652, 
0.03710493756184187, 0.06117569980620832, 0.07227054998040688, 0.06117569980620832, 0.03710493756184187, 
0.03140865154930652, 0.05178411189334978, 0.06117569980620832, 0.05178411189334978, 0.03140865154930652, 
0.01905031014488527, 0.03140865154930652, 0.03710493756184187, 0.03140865154930652, 0.01905031014488527
);

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
	vec3 currentSample = vec3(0.0);
	vec3 blurSample = vec3(0.0);
	
	// If blur is being used, accumulate samples weighted against the Gaussian kernel
	if(amount > 0)
	{
		for(int y = -2; y < 3; y++)
		{
			for(int x = -2; x < 3; x++)
			{
				blurSample += Texel(texture, ((screen_coords + vec2(x,y)) / love_ScreenSize)).rgb * simpleGaussianKernel[((y + 2) * 5) + (x + 2)];
			}
		}
	}
	
	// Sample the framebuffer texture
	currentSample = Texel(texture, texture_coords).rgb;
	
	// Mix between blurSample and color
	if(fade == 1.0)
	{
		return vec4(mix(blurSample, color.rgb, (amount / 120)), color.a);
	}
	// Mix between currentSample and blurSample
	if(amount > 0)
	{
		return vec4(mix(currentSample, blurSample, (amount / 30)), color.a);
	}
	// Use currentSample
	else
	{
		return vec4(currentSample, color.a);
	}
}
#endif
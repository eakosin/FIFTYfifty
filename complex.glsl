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
extern vec2 uiBound; // Bounds of the UI to blur behind
varying vec4 vpos; // Unused vertex position

#ifdef VERTEX
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
    vpos = vertex_position;
    return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL

// 9x9 Gaussian kernel or radius 10
const float complexGaussianKernel[81] = float[81](
0.004479066958912953, 0.006356098569369624, 0.008161392114043155, 0.009482184826427886, 0.009968346838518933, 0.009482184826427886, 0.008161392114043155, 0.006356098569369624, 0.004479066958912953, 
0.006356098569369624, 0.009019733215452408, 0.011581566700383492, 0.01345586077694712, 0.014145757511664327, 0.01345586077694712, 0.011581566700383492, 0.009019733215452408, 0.006356098569369624, 
0.008161392114043155, 0.011581566700383492, 0.01487102600835672, 0.01727766724101169, 0.01816351218327846, 0.01727766724101169, 0.01487102600835672, 0.011581566700383492, 0.008161392114043155, 
0.009482184826427886, 0.01345586077694712, 0.01727766724101169, 0.020073785435072034, 0.021102990422745223, 0.020073785435072034, 0.01727766724101169, 0.01345586077694712, 0.009482184826427886, 
0.009968346838518933, 0.014145757511664327, 0.01816351218327846, 0.021102990422745223, 0.022184963878532086, 0.021102990422745223, 0.01816351218327846, 0.014145757511664327, 0.009968346838518933, 
0.009482184826427886, 0.01345586077694712, 0.01727766724101169, 0.020073785435072034, 0.021102990422745223, 0.020073785435072034, 0.01727766724101169, 0.01345586077694712, 0.009482184826427886, 
0.008161392114043155, 0.011581566700383492, 0.01487102600835672, 0.01727766724101169, 0.01816351218327846, 0.01727766724101169, 0.01487102600835672, 0.011581566700383492, 0.008161392114043155, 
0.006356098569369624, 0.009019733215452408, 0.011581566700383492, 0.01345586077694712, 0.014145757511664327, 0.01345586077694712, 0.011581566700383492, 0.009019733215452408, 0.006356098569369624, 
0.004479066958912953, 0.006356098569369624, 0.008161392114043155, 0.009482184826427886, 0.009968346838518933, 0.009482184826427886, 0.008161392114043155, 0.006356098569369624, 0.004479066958912953
);

// Reweighted 3x3 r=0.75 Gaussian kernel with edge weighting for blue and red to simulate chromatic abberation
const vec3 cinematicKernel[9] = vec3[9](
vec3(0.0000000000000000000, 0.04416589065853191, 0.0922903086524308425), vec3(0.10497808951021347), vec3(0.0922903086524308425, 0.04416589065853191, 0.0000000000000000000),
vec3(0.0112445223775533675, 0.10497808951021347, 0.1987116566428735725), vec3(0.40342407932501833), vec3(0.1987116566428735725, 0.10497808951021347, 0.0112445223775533675),
vec3(0.0000000000000000000, 0.04416589065853191, 0.0922903086524308425), vec3(0.10497808951021347), vec3(0.0922903086524308425, 0.04416589065853191, 0.0000000000000000000)
);

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
	float contrast = 2.0;
	vec3 currentSample = vec3(0.0);
	vec3 blurSample = vec3(0.0);
	vec3 bloomSample = vec3(0.0);
	vec3 cinematicSample = vec3(0.0);
	
	// If blur is being used or the fragment is under a ui element, accumulate samples weighted against the Gaussian kernel
	if(amount > 0 || (screen_coords.y < uiBound.x || uiBound.y < screen_coords.y))
	{
		for(int y = -4; y < 5; y++)
		{
			for(int x = -4; x < 5; x++)
			{
				currentSample = Texel(texture, ((screen_coords + vec2(x,y)) / love_ScreenSize)).rgb * complexGaussianKernel[((y + 4) * 9) + (x + 4)];
				blurSample += currentSample;
			}
		}
	}
	
	// Accumulate samples against the cinematic kernel
	for(int y = -1; y < 2; y++)
	{
		for(int x = -1; x < 2; x++)
		{
			cinematicSample += Texel(texture, ((screen_coords + vec2(x,y)) / love_ScreenSize)).rgb * cinematicKernel[((y + 1) * 3) + (x + 1)];
		}
	}
	
	// Accumulate samples with increased contrast using a box blur for bloom
	for(int y = -5; y < 6; y++)
	{
		for(int x = -5; x < 6; x++)
		{
			bloomSample += clamp(((Texel(texture, ((screen_coords + vec2(x,y)) / love_ScreenSize)).rgb - 0.5) * contrast) + 0.5, 0.0, 1.0);
		}
	}
	bloomSample *= 0.008264462809917; // 11x11
	//bloomSample *= 0.01234567901234; // 9x9
	cinematicSample = clamp((cinematicSample) + clamp(bloomSample * 0.25, 0.0, 1.0), 0.0, 1.0);
	
	// Mix between blurSample and color
	if(fade == 1.0)
	{
		return vec4(mix(blurSample, color.rgb, (amount / 120)), color.a);
	}
	// Use blurSample if under a ui element
	else if(screen_coords.y < uiBound.x || uiBound.y < screen_coords.y)
	{
		return vec4(blurSample, color.a);
	}
	// Mix between cinematicSample and blurSample
	else if(amount > 0)
	{
		return vec4(mix(cinematicSample, blurSample, (amount / 30)), color.a);
	}
	// Use cinematicSample
	else
	{
		return vec4(cinematicSample, color.a);
	}
}
#endif
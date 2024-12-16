///..................DISPLACEMENT.......................///
float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }

float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }

float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }

float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }

float snoise( float3 v )
{
	const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
	float3 i = floor( v + dot( v, C.yyy ) );
	float3 x0 = v - i + dot( i, C.xxx );
	float3 g = step( x0.yzx, x0.xyz );
	float3 l = 1.0 - g;
	float3 i1 = min( g.xyz, l.zxy );
	float3 i2 = max( g.xyz, l.zxy );
	float3 x1 = x0 - i1 + C.xxx;
	float3 x2 = x0 - i2 + C.yyy;
	float3 x3 = x0 - 0.5;
	i = mod3D289( i);
	float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
	float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
	float4 x_ = floor( j / 7.0 );
	float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
	float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
	float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
	float4 h = 1.0 - abs( x ) - abs( y );
	float4 b0 = float4( x.xy, y.xy );
	float4 b1 = float4( x.zw, y.zw );
	float4 s0 = floor( b0 ) * 2.0 + 1.0;
	float4 s1 = floor( b1 ) * 2.0 + 1.0;
	float4 sh = -step( h, 0.0 );
	float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
	float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
	float3 g0 = float3( a0.xy, h.x );
	float3 g1 = float3( a0.zw, h.y );
	float3 g2 = float3( a1.xy, h.z );
	float3 g3 = float3( a1.zw, h.w );
	float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
	g0 *= norm.x;
	g1 *= norm.y;
	g2 *= norm.z;
	g3 *= norm.w;
	float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
	m = m* m;
	m = m* m;
	float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
	return 42.0 * dot( m, px);
}

float GetNoise(float2 uv, float scale, float amplitude, float animationSpeed)
{
	float3 p = float3(uv.x, uv.y, _TimeParameters.x * animationSpeed);
	return snoise(p * scale) * amplitude;
}

sampler2D _PaintTexture;
float GetPaint(float2 uv)
{
	float2 paintMask = tex2Dlod(_PaintTexture, float4( uv.xy, 0.0, 0.0));
	return (paintMask.r + 0.5) * (1 - (paintMask.g + 0.5)) - 0.5;
}

//...........LIGHTING..............//

float PerceptualRoughnessToMipmap(float perceptualRoughness, float lodSteps)
{
    perceptualRoughness = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);
    return perceptualRoughness * lodSteps;
}

float DiffuseLighting(float3 normal, float3 lightDir)
{
    return smoothstep(-1, 1, dot(normal, lightDir));
}

half3 SpecularLighting(float3 normal, float3 viewDir, float3 lightDir, float smoothness, half3 glossinessColor)
{
	float3 halfDir = normalize(lightDir + viewDir); 
	float N = smoothness * 128.0;
	float energyCompensation = (N + 2.0) / 8.0;
	float specIntensity = pow(max(dot(normal, halfDir), 0.0), N); 

	return specIntensity * glossinessColor * energyCompensation;
}

half3 SpecularEnvironment(samplerCUBE Cubemap, half roughness, float lodSteps, float3 viewDir, float3 normal)
{
	float3 coords = reflect(-viewDir, normal);
	float mip = PerceptualRoughnessToMipmap(roughness, lodSteps);
	half3 specEnv = texCUBElod(Cubemap, float4(coords.x, coords.y, coords.z, mip)).rgb;
	return specEnv;
}

half3 CalculateLighting (sampler2D DiffuseGradientTex, half3 DiffuseTint, half3 glossinessColor, 
	float smoothness, float3 normal, float3 lightDir, float3 viewDir) 
{
	float diff = DiffuseLighting(normal, lightDir);
	half3 diffColored = tex2D(DiffuseGradientTex, float2(diff, 0)).rgb * DiffuseTint;

	smoothness = max(smoothness, 0.001);
	half3 specColored = SpecularLighting(normal, viewDir, lightDir, smoothness, glossinessColor);

	return diffColored + specColored;
}

//..........HELPERS..........//

half3 BlendSoftLight(half3 baseColor, half3 blendColor, half alpha)
{
    half3 softLight = lerp(
        2.0 * baseColor * blendColor + baseColor * baseColor * (1.0 - 2.0 * blendColor),
        sqrt(baseColor) * (2.0 * blendColor - 1.0) + 2.0 * baseColor * (1.0 - blendColor),
        step(0.5, blendColor)
    );

    return lerp(baseColor, saturate(softLight), alpha);
}

half3 Desaturation(half3 color, half desaturationAmount)
{
    half luminance = dot(color, half3(0.299, 0.587, 0.114));
    return lerp(color, half3(luminance, luminance, luminance), desaturationAmount);
}

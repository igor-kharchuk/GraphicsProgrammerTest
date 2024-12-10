///..................FBM NOISE.......................///
/*
float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }

float snoise( float2 v )
{
	const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
	float2 i = floor( v + dot( v, C.yy ) );
	float2 x0 = v - i + dot( i, C.xx );
	float2 i1;
	i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
	float4 x12 = x0.xyxy + C.xxzz;
	x12.xy -= i1;
	i = mod2D289( i );
	float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
	float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
	m = m * m;
	m = m * m;
	float3 x = 2.0 * frac( p * C.www ) - 1.0;
	float3 h = abs( x ) - 0.5;
	float3 ox = floor( x + 0.5 );
	float3 a0 = x - ox;
	m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
	float3 g;
	g.x = a0.x * x0.x + h.x * x0.y;
	g.yz = a0.yz * x12.xz + h.yz * x12.yw;
	return 130.0 * dot( m, g );
}

float fbm(float2 p, float noiseScale, float amplitudeScaler, int octaves, float lacunarity, float gain)
{
    float amplitude = 1.0;
    float frequency = 1.0;
    float sum = 0.0;       
    float totalAmplitude = 0.0; 
	
	p *= noiseScale;

    for (int i = 0; i < octaves; i++)
    {
        sum += snoise(p * frequency) * amplitude;

        totalAmplitude += amplitude;

        frequency *= lacunarity;
        amplitude *= gain;
    }

    return (sum / totalAmplitude) * amplitudeScaler;
} */

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

float3 SpecularLighting(float3 normal, float3 viewDir, float3 lightDir, float smoothness, float3 glossinessColor)
{
	float3 halfDir = normalize(lightDir + viewDir); 
	float N = smoothness * 128.0;
	float energyCompensation = (N + 2.0) / 8.0;
	float specIntensity = pow(max(dot(normal, halfDir), 0.0), N); 

	return specIntensity * glossinessColor * energyCompensation;
}

float3 SpecularEnvironment(samplerCUBE Cubemap, float roughness, float lodSteps, float3 viewDir, float3 normal)
{
	float3 coords = reflect(-viewDir, normal);
	float mip = PerceptualRoughnessToMipmap(roughness, lodSteps);
	float3 specEnv = texCUBElod(Cubemap, float4(coords.x, coords.y, coords.z, mip)).rgb;
	return specEnv;
}

float3 CalculateLighting (sampler2D DiffuseGradientTex, float3 DiffuseTint, float3 glossinessColor, 
	float smoothness, float3 normal, float3 lightDir, float3 viewDir) 
{
	float diff = DiffuseLighting(normal, lightDir);
	float3 diffColored = tex2D(DiffuseGradientTex, float2(diff, 0)).rgb * DiffuseTint;

	smoothness = max(smoothness, 0.001);
	float3 specColored = SpecularLighting(normal, viewDir, lightDir, smoothness, glossinessColor);

	return diffColored + specColored;
}

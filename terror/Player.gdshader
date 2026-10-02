
shader_type canvas_item;

uniform sampler2D tela : hint_screen_texture,
    repeat_disable, filter_linear;

// CONFIGURAÇÕES DO VHS — INTENSIDADE REDUZIDA
const float RUIDO = 0.045;
const float LINHAS = 0.07;
const float DISTORCAO = 0.003;
const float ABERRACAO_CROMATICA = 0.001;
const float VINHETA = 0.22;
const float VELOCIDADE_FITA = 0.7;

float hash(vec2 p) {
    return fract(
        sin(dot(p, vec2(127.1, 311.7))) * 43758.5453
    );
}

void fragment() {
    vec2 uv = SCREEN_UV;

    // Pequena distorção horizontal
    float faixa = floor(uv.y * 90.0);

    float deslocamento = (
        hash(vec2(faixa, floor(TIME * 12.0 * VELOCIDADE_FITA)))
        - 0.5
    ) * DISTORCAO;

    float ondulacao = sin(
        uv.y * 180.0 + TIME * 5.0 * VELOCIDADE_FITA
    ) * DISTORCAO * 0.15;

    uv.x += deslocamento + ondulacao;

    // Separação sutil das cores
    float r = texture(
        tela, uv + vec2(ABERRACAO_CROMATICA, 0.0)
    ).r;

    float g = texture(tela, uv).g;

    float b = texture(
        tela, uv - vec2(ABERRACAO_CROMATICA, 0.0)
    ).b;

    vec3 cor = vec3(r, g, b);

    // Granulação reduzida
    float ruido = hash(
        floor(uv * vec2(900.0, 500.0))
        + floor(TIME * 24.0 * VELOCIDADE_FITA)
    );

    cor += (ruido - 0.5) * RUIDO;

    // Linhas horizontais discretas
    float linha = sin(SCREEN_UV.y * 900.0) * 0.5 + 0.5;
    cor *= 1.0 - linha * LINHAS;

    // Faixa de tracking mais suave
    float posicao_faixa = fract(TIME * 0.12 * VELOCIDADE_FITA);

    float distancia_faixa = abs(
        SCREEN_UV.y - posicao_faixa
    );

    float tracking = 1.0 - smoothstep(
        0.0, 0.035, distancia_faixa
    );

    cor += tracking * 0.025;

    // Cores levemente desbotadas
    float cinza = dot(cor, vec3(0.299, 0.587, 0.114));
    cor = mix(cor, vec3(cinza), 0.06);

    // Vinheta discreta
    float distancia = distance(SCREEN_UV, vec2(0.5));
    float vinheta = smoothstep(0.25, 0.75, distancia);

    cor *= 1.0 - vinheta * VINHETA;

    COLOR = vec4(clamp(cor, 0.0, 1.0), 1.0);
}
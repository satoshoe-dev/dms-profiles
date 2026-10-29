// Profiles: preview image inside a shape (profile picker).
//
// Crops the image like PreserveAspectCrop, masks it with a shape (rounded
// rectangle, circle, hexagon, diamond), draws the border exactly on the shape
// edge and, when selected, a soft glow outwards. Everything is based on signed
// distance functions, so edges stay smooth at any size.

#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;

    float shape;        // 0 rectangle, 1 circle, 2 hexagon, 3 diamond
    float areaW;        // whole item in px, including padding
    float areaH;
    float padding;      // px of room outside the card for the glow
    float imageW;
    float imageH;
    float corner;       // px corner radius
    float border;       // px border width
    float glow;         // 0..1 outer glow
    float dim;          // 0..1 darken
    float skew;         // frame shear: x moves by skew * y, the picture stays upright
    vec4 borderColor;
} ubuf;

layout(binding = 1) uniform sampler2D source;

float boxDistance(vec2 p, vec2 halfSize, float r) {
    vec2 q = abs(p) - (halfSize - r);
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// hexagon with flat top and bottom edges, inner radius r
float hexagonDistance(vec2 p, float r) {
    const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);
    p = abs(p.yx);
    p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
    p -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
    return length(p) * sign(p.y);
}

float ndot(vec2 a, vec2 b) {
    return a.x * b.x - a.y * b.y;
}

float diamondDistance(vec2 p, vec2 b) {
    vec2 q = abs(p);
    float h = clamp((-2.0 * ndot(q, b) + ndot(b, b)) / dot(b, b), -1.0, 1.0);
    float d = length(q - 0.5 * b * vec2(1.0 - h, 1.0 + h));
    return d * sign(q.x * b.y + q.y * b.x - b.x * b.y);
}

void main() {
    vec2 area = vec2(ubuf.areaW, ubuf.areaH);
    vec2 card = area - 2.0 * ubuf.padding;
    // a sheared frame needs |skew| * height of extra width; the box itself is narrower
    vec2 halfSize = vec2(card.x - abs(ubuf.skew) * card.y, card.y) * 0.5;
    vec2 p = qt_TexCoord0 * area - area * 0.5;
    // the frame is measured in sheared space, the picture in plain space
    vec2 q = vec2(p.x - ubuf.skew * p.y, p.y);
    int shape = int(ubuf.shape + 0.5);

    float d;
    if (shape == 1) {
        d = length(q) - min(halfSize.x, halfSize.y);
    } else if (shape == 2) {
        float r = min(halfSize.y, halfSize.x * 0.866025404) - ubuf.corner * 0.5;
        d = hexagonDistance(q, r) - ubuf.corner * 0.5;
    } else if (shape == 3) {
        float r = min(halfSize.x, halfSize.y);
        d = diamondDistance(q, vec2(r) - ubuf.corner * 0.7) - ubuf.corner * 0.5;
    } else {
        d = boxDistance(q, halfSize, min(ubuf.corner, min(halfSize.x, halfSize.y)));
    }

    // crop like PreserveAspectCrop
    vec2 c = p / card + 0.5;
    float cardAspect = card.x / card.y;
    float imageAspect = ubuf.imageW / max(1.0, ubuf.imageH);
    if (imageAspect > cardAspect)
        c.x = (c.x - 0.5) * cardAspect / imageAspect + 0.5;
    else
        c.y = (c.y - 0.5) * imageAspect / cardAspect + 0.5;
    vec3 col = texture(source, clamp(c, 0.0, 1.0)).rgb * (1.0 - ubuf.dim);

    float inside = clamp(0.5 - d, 0.0, 1.0);
    if (ubuf.border > 0.0) {
        float band = clamp(0.5 - (abs(d + ubuf.border * 0.5) - ubuf.border * 0.5), 0.0, 1.0);
        col = mix(col, ubuf.borderColor.rgb, band);
    }

    // The glow must reach 0 before the edge of the item. Otherwise about 3 %
    // remains at the padding edge and shows as a line on dark backgrounds.
    float fadeOut = 1.0 - smoothstep(ubuf.padding * 0.25, ubuf.padding * 0.95, max(d, 0.0));
    float halo = ubuf.glow * exp(-max(d, 0.0) / max(1.0, ubuf.padding * 0.3)) * 0.55 * fadeOut * fadeOut;
    vec4 insideColor = vec4(col * inside, inside);
    vec4 haloColor = vec4(ubuf.borderColor.rgb * halo, halo) * (1.0 - inside);
    fragColor = (insideColor + haloColor) * ubuf.qt_Opacity;
}

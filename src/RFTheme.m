// Visual inspirado nas caixas e propagandas da era 16 bits: grade cinza sobre preto,
// letreiros cromados em itálico, vermelho forte e faixas diagonais. Nada de logos.

#import "RF.h"
#import <QuartzCore/QuartzCore.h>

UIColor *RFThemeRed(void) {
    return [UIColor colorWithRed:0.89 green:0.16 blue:0.14 alpha:1];
}

UIColor *RFThemeText(void) {
    return [UIColor colorWithWhite:0.94 alpha:1];
}

UIColor *RFThemeDim(void) {
    return [UIColor colorWithWhite:0.58 alpha:1];
}

UIColor *RFThemeCard(void) {
    return [UIColor colorWithRed:0.085 green:0.085 blue:0.095 alpha:1];
}

UIFont *RFThemeDisplayFont(CGFloat size) {
    return [UIFont fontWithName:@"HelveticaNeue-CondensedBlack" size:size] ?: [UIFont boldSystemFontOfSize:size];
}

UIFont *RFThemeLabelFont(CGFloat size) {
    return [UIFont fontWithName:@"HelveticaNeue-Bold" size:size] ?: [UIFont boldSystemFontOfSize:size];
}

// Grade cinza fina sobre preto, como fundo de caixa de cartucho
UIColor *RFThemeGridColor(void) {
    static UIColor *color;
    if (color) return color;
    CGFloat cell = 22;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(cell, cell), YES, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor colorWithRed:0.035 green:0.035 blue:0.04 alpha:1] setFill];
    CGContextFillRect(ctx, CGRectMake(0, 0, cell, cell));
    [[UIColor colorWithWhite:0.20 alpha:1] setFill];
    CGFloat px = 1.0 / [UIScreen mainScreen].scale;
    CGContextFillRect(ctx, CGRectMake(0, 0, cell, px * 2));
    CGContextFillRect(ctx, CGRectMake(0, 0, px * 2, cell));
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    color = [UIColor colorWithPatternImage:img];
    return color;
}

UIView *RFThemeGridView(void) {
    UIView *v = [[UIView alloc] init];
    v.backgroundColor = RFThemeGridColor();
    return v;
}

// Três faixas diagonais (vermelho, laranja, amarelo) a partir de x, na altura do retângulo
void RFThemeDrawStripes(CGContextRef ctx, CGRect r, CGFloat width) {
    NSArray *colors = @[RFThemeRed(),
                        [UIColor colorWithRed:0.96 green:0.45 blue:0.13 alpha:1],
                        [UIColor colorWithRed:0.98 green:0.76 blue:0.20 alpha:1]];
    CGFloat slant = r.size.height * 0.45;
    CGFloat x = r.origin.x;
    for (NSInteger i = 0; i < 3; i++) {
        CGFloat w = width * (1.0 - i * 0.3);
        UIBezierPath *p = [UIBezierPath bezierPath];
        [p moveToPoint:CGPointMake(x + slant, CGRectGetMinY(r))];
        [p addLineToPoint:CGPointMake(x + slant + w, CGRectGetMinY(r))];
        [p addLineToPoint:CGPointMake(x + w, CGRectGetMaxY(r))];
        [p addLineToPoint:CGPointMake(x, CGRectGetMaxY(r))];
        [p closePath];
        [colors[i] setFill];
        [p fill];
        x += w + width * 0.35;
    }
    (void)ctx;
}

// Letreiro cromado em itálico: contorno escuro + preenchimento em degradê metálico
UIImage *RFThemeChromeText(NSString *text, CGFloat size) {
    UIFont *font = RFThemeDisplayFont(size);
    NSDictionary *attrs = @{NSFontAttributeName: font, NSForegroundColorAttributeName: [UIColor whiteColor]};
    CGSize ts = [text sizeWithAttributes:attrs];
    CGFloat skew = 0.22;   // inclinação do itálico
    CGFloat pad = size * 0.12;
    CGSize canvas = CGSizeMake(ceil(ts.width + ts.height * skew + pad * 2), ceil(ts.height + pad * 2));
    CGFloat scale = [UIScreen mainScreen].scale;

    void (^drawText)(CGContextRef, NSDictionary *) = ^(CGContextRef c, NSDictionary *a) {
        CGContextSaveGState(c);
        // Inclina em torno da base do texto
        CGContextTranslateCTM(c, pad, pad + ts.height);
        CGContextConcatCTM(c, CGAffineTransformMake(1, 0, -skew, 1, 0, 0));
        CGContextTranslateCTM(c, 0, -ts.height);
        [text drawAtPoint:CGPointZero withAttributes:a];
        CGContextRestoreGState(c);
    };

    // 1) Máscara em tons de cinza com o texto
    size_t mw = (size_t)(canvas.width * scale), mh = (size_t)(canvas.height * scale);
    CGColorSpaceRef gray = CGColorSpaceCreateDeviceGray();
    CGContextRef mctx = CGBitmapContextCreate(NULL, mw, mh, 8, mw, gray, (CGBitmapInfo)kCGImageAlphaNone);
    CGColorSpaceRelease(gray);
    CGContextSetGrayFillColor(mctx, 0, 1);
    CGContextFillRect(mctx, CGRectMake(0, 0, mw, mh));
    CGContextTranslateCTM(mctx, 0, mh);
    CGContextScaleCTM(mctx, scale, -scale);
    UIGraphicsPushContext(mctx);
    drawText(mctx, attrs);
    UIGraphicsPopContext();
    CGImageRef mask = CGBitmapContextCreateImage(mctx);
    CGContextRelease(mctx);

    // 2) Contorno + degradê recortado pela máscara
    UIGraphicsBeginImageContextWithOptions(canvas, NO, scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    NSDictionary *strokeAttrs = @{NSFontAttributeName: font,
                                  NSStrokeColorAttributeName: [UIColor colorWithWhite:0.02 alpha:1],
                                  NSStrokeWidthAttributeName: @(size > 40 ? 9 : 7)};
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, size * 0.04), size * 0.08, [UIColor colorWithWhite:0 alpha:0.8].CGColor);
    drawText(ctx, strokeAttrs);
    CGContextSetShadowWithColor(ctx, CGSizeZero, 0, NULL);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, 0, canvas.height);
    CGContextScaleCTM(ctx, 1, -1);
    CGContextClipToMask(ctx, CGRectMake(0, 0, canvas.width, canvas.height), mask);
    // Cromado: céu claro em cima, "horizonte" escuro no meio, reflexo embaixo
    CGFloat comps[] = {
        1.00, 1.00, 1.00, 1,
        0.80, 0.84, 0.90, 1,
        0.42, 0.45, 0.52, 1,
        0.88, 0.88, 0.92, 1,
        0.60, 0.62, 0.68, 1,
    };
    CGFloat locs[] = {0.0, 0.42, 0.50, 0.70, 1.0};
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    CGGradientRef g = CGGradientCreateWithColorComponents(rgb, comps, locs, 5);
    CGColorSpaceRelease(rgb);
    // Coordenadas viradas: o topo do texto está em y = altura
    CGContextDrawLinearGradient(ctx, g, CGPointMake(0, canvas.height - pad), CGPointMake(0, pad), 0);
    CGGradientRelease(g);
    CGContextRestoreGState(ctx);
    CGImageRelease(mask);

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

void RFThemeApplyNavigationBar(UINavigationBar *bar) {
    bar.barStyle = UIBarStyleBlack;
    bar.barTintColor = [UIColor colorWithWhite:0.02 alpha:1];
    bar.translucent = NO;
    bar.tintColor = RFThemeRed();
    bar.titleTextAttributes = @{NSFontAttributeName: RFThemeDisplayFont(22), NSForegroundColorAttributeName: RFThemeText()};
}

// Tabelas agrupadas (telas de Controle): fundo de grade e células escuras
void RFThemeApplyTable(UITableView *table) {
    table.backgroundView = RFThemeGridView();
    table.backgroundColor = [UIColor blackColor];
    table.separatorColor = [UIColor colorWithWhite:0.18 alpha:1];
    table.indicatorStyle = UIScrollViewIndicatorStyleWhite;
}

void RFThemeStyleCell(UITableViewCell *cell) {
    cell.backgroundColor = RFThemeCard();
    if ([cell.textLabel.textColor isEqual:[UIColor blackColor]] || !cell.textLabel.textColor) cell.textLabel.textColor = RFThemeText();
    cell.detailTextLabel.textColor = RFThemeDim();
    UIView *sel = [[UIView alloc] init];
    sel.backgroundColor = [RFThemeRed() colorWithAlphaComponent:0.35];
    cell.selectedBackgroundView = sel;
}

void RFThemeStyleHeaderFooter(UIView *view, BOOL header) {
    if (![view isKindOfClass:[UITableViewHeaderFooterView class]]) return;
    UITableViewHeaderFooterView *v = (UITableViewHeaderFooterView *)view;
    v.textLabel.textColor = header ? RFThemeRed() : RFThemeDim();
    if (header) v.textLabel.font = RFThemeLabelFont(13);
}

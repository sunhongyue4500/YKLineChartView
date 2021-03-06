//
//  YKLineChartView.m
//  YKLineChartView
//
//  Created by chenyk on 15/12/9.
//  Copyright © 2015年 chenyk. All rights reserved.
//  https://github.com/chenyk0317/YKLineChartView

#import "YKLineChartView.h"
#import "YKLineDataSet.h"
#import "YKLineEntity.h"
@interface YKLineChartView()
@property (nonatomic,strong)YKLineDataSet * dataSet;
;




@property (nonatomic,assign)NSInteger countOfshowCandle;

@property (nonatomic,assign)NSInteger  startDrawIndex;

@property (nonatomic,strong)UIPanGestureRecognizer * panGesture;
@property (nonatomic,strong)UIPinchGestureRecognizer * pinGesture;
@property (nonatomic,strong)UILongPressGestureRecognizer * longPressGesture;
@property (nonatomic,strong)UITapGestureRecognizer * tapGesture;

@property (nonatomic,assign)CGFloat lastPinScale;

@property (nonatomic,assign)CGFloat lastPinCount;

@end
@implementation YKLineChartView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
        
    }
    return self;
}

- (void)commonInit {
    
    self.candleCoordsScale = 0.f;
    
    [self addGestureRecognizer:self.panGesture];
    [self addGestureRecognizer:self.pinGesture];
    [self addGestureRecognizer:self.longPressGesture];
    [self addGestureRecognizer:self.tapGesture];
}

/** 显示多少个*/
- (NSInteger)countOfshowCandle{
    return self.contentWidth/(self.candleWidth);
}

- (void)setStartDrawIndex:(NSInteger)startDrawIndex
{
    if (startDrawIndex <= 0) {
        startDrawIndex = 0;
    } else  if (startDrawIndex + self.countOfshowCandle >= self.dataSet.data.count) {
        startDrawIndex = self.dataSet.data.count - self.countOfshowCandle;
    }
    _startDrawIndex = startDrawIndex;
}

- (void)setCandleWidth:(CGFloat)candleWidth {
    if (candleWidth >= self.candleMaxWidth) _candleWidth = self.candleMaxWidth;
    else if (candleWidth <= self.candleMinWidth) _candleWidth = self.candleMinWidth;
    else  _candleWidth = candleWidth;
}

-(void)setupData:(YKLineDataSet *)dataSet
{
    self.dataSet = dataSet;
    [self notifyDataSetChanged];
}

- (void)addDataSetWithArray:(NSArray *)array
{
    NSArray * tempArray = [self.dataSet.data mutableCopy];
    [self.dataSet.data removeAllObjects];
    [self.dataSet.data addObjectsFromArray:array];
    [self.dataSet.data addObjectsFromArray:tempArray];
    self.startDrawIndex += array.count;
    [self setCurrentDataMaxAndMin];
    [self setNeedsDisplay];
}

/** 设置最大最小范围*/
- (void)setCurrentDataMaxAndMin
{
    if (self.dataSet.data.count > 0) {
        //self.maxPrice = CGFLOAT_MIN;
        //self.minPrice = CGFLOAT_MAX;
        //self.maxVolume = CGFLOAT_MIN;
        
        NSInteger idx = self.startDrawIndex;
        for (NSInteger i = idx; i < self.startDrawIndex + self.countOfshowCandle && i < self.dataSet.data.count; i++) {
            YKLineEntity  * entity = [self.dataSet.data objectAtIndex:i];
            self.minPrice = (self.minPrice < entity.elevation ? self.minPrice : entity.elevation);
            self.maxPrice = (self.maxPrice > entity.elevation ? self.maxPrice : entity.elevation);
        }
        if (self.maxPrice - self.minPrice < 0.3) {
            self.maxPrice +=0.5;
            self.minPrice -=0.5;
        }
    }
}

- (void)drawRect:(CGRect)rect
{   
    [super drawRect:rect];
    // 只需在数据源变化后再设置
    [self setCurrentDataMaxAndMin];
    
    CGContextRef optionalContext = UIGraphicsGetCurrentContext();
    
    [self drawGridBackground:optionalContext rect:rect];
    
    
    if (self.dataSet.data.count) {
        [self drawCandle:optionalContext];
        
    }
    //[self drawLabelPrice:optionalContext];
}

- (void)drawGridBackground:(CGContextRef)context rect:(CGRect)rect
{
    [super drawGridBackground:context rect:rect];
}

- (void)drawAvgMarker:(CGContextRef)context
                 idex:(NSInteger)idex
          isDrawRight:(BOOL)isDrawRight
{
    
    if (!self.isShowAvgMarkerEnabled) {
        return;
    }
    
    YKLineEntity  * entity;
    if (0 == idex) {
        entity = [self.dataSet.data lastObject];
    }else{
        entity = self.dataSet.data[idex];
    }
    NSDictionary * drawAttributes = self.avgLabelAttributedDic ?:self.defaultAttributedDic;
    
    
    NSString * ma5Str = [NSString stringWithFormat:@"MA5 %.2f",entity.ma5];
    NSMutableAttributedString * ma5StrAtt = [[NSMutableAttributedString alloc]initWithString:ma5Str attributes:drawAttributes];
    CGSize ma5StrAttSize = [ma5StrAtt size];
    
    NSString * ma10Str = [NSString stringWithFormat:@"MA10 %.2f",entity.ma10];
    NSMutableAttributedString * ma10StrAtt = [[NSMutableAttributedString alloc]initWithString:ma10Str attributes:drawAttributes];
    CGSize ma10StrAttSize = [ma10StrAtt size];
    
    NSString * ma20Str = [NSString stringWithFormat:@"MA20 %.2f",entity.ma20];
    NSMutableAttributedString * ma20StrAtt = [[NSMutableAttributedString alloc]initWithString:ma20Str attributes:drawAttributes];
    CGSize ma20StrAttSize = [ma20StrAtt size];
    
    
    CGFloat radius = ma5StrAttSize.height/2;
    CGFloat length = ma5StrAttSize.width+ma20StrAttSize.width+ma10StrAttSize.width+radius*8;
    CGFloat space = radius;
    
    CGPoint startP = CGPointMake(self.contentLeft, self.contentTop);
    if (isDrawRight) {
        startP.x = self.contentRight - length - 4;
    }
    
    startP.y = startP.y+(radius/2.0)+2;
    CGFloat labelY = self.contentTop+(radius/4.0);
    //Background
    UIColor * bgColor = [UIColor colorWithWhite:1 alpha:0.5];
    [self drawRect:context rect:CGRectMake(startP.x, self.contentTop+1,length, ma5StrAttSize.height) color:bgColor];
    
    //=====
    CGContextSetFillColorWithColor(context, self.dataSet.avgMA5Color.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(startP.x+(radius/2.0),startP.y , radius, radius));
    
    startP.x += (radius+space);
    [self drawLabel:context attributesText:ma5StrAtt rect:CGRectMake(startP.x,labelY, ma5StrAttSize.width, ma5StrAttSize.height)];
    startP.x += (ma5StrAttSize.width + space);
    
    //=====
    
    CGContextSetFillColorWithColor(context, self.dataSet.avgMA10Color.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(startP.x+(radius/2.0),startP.y, radius, radius));
    startP.x += (radius+space);
    
    [self drawLabel:context attributesText:ma10StrAtt rect:CGRectMake(startP.x,labelY, ma10StrAttSize.width, ma10StrAttSize.height)];
    startP.x += (ma10StrAttSize.width + space);
    
    //=====
    CGContextSetFillColorWithColor(context, self.dataSet.avgMA20Color.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(startP.x+(radius/2.0), startP.y, radius, radius));
    
    startP.x += (radius+space);
    
    [self drawLabel:context attributesText:ma20StrAtt rect:CGRectMake(startP.x, labelY, ma20StrAttSize.width, ma20StrAttSize.height)];
    
}
- (void)drawCandle:(CGContextRef)context
{
    CGContextSaveGState(context);
    NSInteger idex = self.startDrawIndex;
    // 图表尽可能充满空间
    self.candleCoordsScale = (self.uperChartHeightScale * self.contentHeight)/(self.maxPrice-self.minPrice);
    // 下面的图的比例
    self.volumeCoordsScale = (self.contentHeight - (self.uperChartHeightScale * self.contentHeight)-self.xAxisHeitht)/(self.maxVolume - 0);
    
    CGRect labelRect = CGRectZero;
    /** 保存上一次绘制的位置*/
    CGRect lastRect = CGRectZero;
    // 只绘制视野范围内的高程点
    for (NSInteger i = idex ; i < idex + self.countOfshowCandle && i < self.dataSet.data.count; i++) {
        
        YKLineEntity  * entity  = [self.dataSet.data objectAtIndex:i];
        
        //CGFloat left = (self.candleWidth * (i - idex) + self.contentLeft) + self.candleWidth / 6.0;
        //CGFloat candleWidth = self.candleWidth - self.candleWidth / 6.0;
        //CGFloat startX = left + candleWidth/2.0 ;
        //CGFloat candleWidth = self.candleWidth;
        CGFloat left = (self.candleWidth * (i - idex) + self.contentLeft);
        CGFloat startX = left;
        
        if (entity.elevationPointName) {
            [self drawline:context startPoint:CGPointMake(startX, self.contentTop) stopPoint:CGPointMake(startX,  (self.uperChartHeightScale * self.contentHeight)+ self.contentTop) color:self.borderColor lineWidth:0.5];
            [self drawline:context startPoint:CGPointMake(startX, (self.uperChartHeightScale * self.contentHeight)+ self.xAxisHeitht) stopPoint:CGPointMake(startX,self.contentBottom) color:self.borderColor lineWidth:0.5];
            NSString * date = entity.elevationPointName;
            NSDictionary * drawAttributes = self.xAxisAttributedDic?:self.defaultAttributedDic;
            NSMutableAttributedString * dateStrAtt = [[NSMutableAttributedString alloc]initWithString:date attributes:drawAttributes];
            CGSize dateStrAttSize = [dateStrAtt size];
            double labelStartX = startX - dateStrAttSize.width / 2;
            double labelEndX = startX + dateStrAttSize.width / 2;
            // 边界检查
            // 左边界
            if (labelStartX < self.contentLeft) {
                labelStartX = 0;
            }
            // 右边界
            if (labelEndX > self.contentRight) {
                labelStartX = self.contentRight - dateStrAttSize.width;
            }
            labelRect = CGRectMake(labelStartX,((self.uperChartHeightScale * self.contentHeight)+ self.contentTop), dateStrAttSize.width, dateStrAttSize.height);
            // 相交
            if (CGRectEqualToRect(lastRect, CGRectZero) || !isXIntersectionWithRect(labelRect, lastRect)) {
                [self drawLabel:context attributesText:dateStrAtt rect:labelRect];
                lastRect = labelRect;
            }
        }
        
        if (i > 0){
            YKLineEntity * lastEntity = [self.dataSet.data objectAtIndex:i -1];
            CGFloat lastX = startX - self.candleWidth;
            
            CGFloat lastY5 = (self.maxPrice - lastEntity.elevation) *  self.candleCoordsScale + self.contentTop;
            CGFloat  y5 = (self.maxPrice - entity.elevation) * self.candleCoordsScale  + self.contentTop;
            if (entity.elevation > 0 && lastEntity.elevation > 0) {
                [self drawline:context startPoint:CGPointMake(lastX, lastY5) stopPoint:CGPointMake(startX, y5) color:self.dataSet.avgMA5Color lineWidth:self.dataSet.avgLineWidth];
            }
            
            CGFloat lastY10 = (self.maxPrice - lastEntity.elevation) * self.candleCoordsScale  + self.contentTop;
            CGFloat  y10 = (self.maxPrice - entity.elevation) * self.candleCoordsScale  + self.contentTop;
            if (entity.elevation > 0 && lastEntity.elevation > 0) {
                [self drawline:context startPoint:CGPointMake(lastX, lastY10) stopPoint:CGPointMake(startX, y10) color:self.dataSet.avgMA10Color lineWidth:self.dataSet.avgLineWidth];
            }
            
            CGFloat lastY20 = (self.maxPrice - lastEntity.elevation) * self.candleCoordsScale  + self.contentTop;
            CGFloat  y20 = (self.maxPrice - entity.elevation) * self.candleCoordsScale  + self.contentTop;
            if (entity.elevation > 0 && lastEntity.elevation >0) {
                [self drawline:context startPoint:CGPointMake(lastX, lastY20) stopPoint:CGPointMake(startX, y20) color:self.dataSet.avgMA20Color lineWidth:self.dataSet.avgLineWidth];
            }
            
        }
        // 下面矩形
        //CGFloat volume = ((entity.volume - 0) * self.volumeCoordsScale);
        //[self drawRect:context rect:CGRectMake(left, self.contentBottom - volume , candleWidth, volume) color:color];
    }
    
    
    for (NSInteger i = idex ; i< self.dataSet.data.count; i ++) {
        YKLineEntity  * entity  = [self.dataSet.data objectAtIndex:i];
        
        CGFloat close = ((self.maxPrice - entity.elevation) * self.candleCoordsScale) + self.contentTop;
        CGFloat left = (self.candleWidth * (i - idex) + self.contentLeft);
        //CGFloat candleWidth = self.candleWidth;
        CGFloat startX = left;
        //十字线
        if (self.highlightLineCurrentEnabled) {
            if (i == self.highlightLineCurrentIndex) {
                
                YKLineEntity * entity;
                if (i < self.dataSet.data.count) {
                    entity = [self.dataSet.data objectAtIndex:i];
                }
                [self drawHighlighted:context point:CGPointMake(startX, close)idex:idex value:entity color:self.dataSet.highlightLineColor lineWidth:self.dataSet.highlightLineWidth];
                
                BOOL isDrawRight = startX < (self.contentRight)/2.0;
                [self drawAvgMarker:context idex:i isDrawRight:isDrawRight];
                if ([self.delegate respondsToSelector:@selector(chartValueSelected:entry:entryIndex:) ]) {
                    [self.delegate chartValueSelected:self entry:entity entryIndex:i];
                }
            }
        }
    }
    
    if (!self.highlightLineCurrentEnabled) {
        [self drawAvgMarker:context idex:0 isDrawRight:NO];;
    }
    CGContextRestoreGState(context);
}


- (UIPanGestureRecognizer *)panGesture
{
    if (!_panGesture) {
        _panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePanGestureAction:)];
    }
    return _panGesture;
}
- (void)handlePanGestureAction:(UIPanGestureRecognizer *)recognizer
{
    if (!self.scrollEnabled) {
        return;
    }
    
    self.highlightLineCurrentEnabled = NO;
    
    CGPoint point = [recognizer translationInView:self];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
    }
    if (recognizer.state == UIGestureRecognizerStateChanged) {
    }
    
    CGFloat offset = point.x;
    
    NSLog(@"%ld=======,%.2f,%.2f",(long)self.startDrawIndex,offset,[recognizer velocityInView:self].x);

    if (offset > 0) {
        // 向右滑
        NSInteger offsetIndex = offset / 4.0 ;
        NSLog(@"%ld",(long)offsetIndex);
        
        self.startDrawIndex  -= offsetIndex;
        if ( self.startDrawIndex < 2) {
            if ([self.delegate respondsToSelector:@selector(chartKlineScrollLeft:)]) {
                [self.delegate chartKlineScrollLeft:self];
            }
        }
    }else{
        // 向左滑
        NSInteger offsetIndex = (-offset) / 4.0;
        self.startDrawIndex += offsetIndex;
    }
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        
    }
    [self setNeedsDisplay];
    [recognizer setTranslation:CGPointMake(0, 0) inView:self];
}

- (UIPinchGestureRecognizer *)pinGesture
{
    if (!_pinGesture) {
        _pinGesture = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(handlePinGestureAction:)];
    }
    return _pinGesture;
}


- (void)handlePinGestureAction:(UIPinchGestureRecognizer *)recognizer
{
    if (!self.zoomEnabled) {
        return;
    }
    
    self.highlightLineCurrentEnabled = NO;
    
    recognizer.scale= recognizer.scale - self.lastPinScale + 1;
    
    self.candleWidth = recognizer.scale * self.candleWidth;
    
    if(self.candleWidth > self.candleMaxWidth){
        self.candleWidth = self.candleMaxWidth;
    }
    if(self.candleWidth < self.candleMinWidth){
        self.candleWidth = self.candleMinWidth;
    }
    
    //self.startDrawIndex = self.dataSet.data.count - self.countOfshowCandle;
    NSInteger offset = (NSInteger)((self.lastPinCount -self.countOfshowCandle)/2);
    
    if (labs(offset)) {
        NSLog(@"offset %ld",(long)offset);
        self.lastPinCount = self.countOfshowCandle;
        self.startDrawIndex = self.startDrawIndex + offset;
        [self setNeedsDisplay];
    }
    
    NSLog(@"%ld",(long)self.startDrawIndex);
    
    self.lastPinScale = recognizer.scale;
}

- (UILongPressGestureRecognizer *)longPressGesture
{
    if (!_longPressGesture) {
        _longPressGesture = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(handleLongPressGestureAction:)];
        _longPressGesture.minimumPressDuration = 0.5;
    }
    return _longPressGesture;
}

- (void)handleLongPressGestureAction:(UIPanGestureRecognizer *)recognizer
{
    if (!self.highlightLineShowEnabled) {
        return;
    }
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint  point = [recognizer locationInView:self];
        
        if (point.x > self.contentLeft && point.x < self.contentRight && point.y >self.contentTop && point.y<self.contentBottom) {
            self.highlightLineCurrentEnabled = YES;
            [self getHighlightByTouchPoint:point];
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        
        CGPoint  point = [recognizer locationInView:self];
        
        if (point.x > self.contentLeft && point.x < self.contentRight && point.y >self.contentTop && point.y<self.contentBottom) {
            self.highlightLineCurrentEnabled = YES;
            [self getHighlightByTouchPoint:point];
        }
    }else if (recognizer.state == UIGestureRecognizerStateEnded) {
        
    }
}

- (void)getHighlightByTouchPoint:(CGPoint) point
{
    
    self.highlightLineCurrentIndex = self.startDrawIndex + (NSInteger)((point.x - self.contentLeft)/self.candleWidth);
    [self setNeedsDisplay];
}

- (UITapGestureRecognizer *)tapGesture
{
    if (!_tapGesture) {
        _tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTapGestureAction:)];
    }
    return _tapGesture;
}
- (void)handleTapGestureAction:(UITapGestureRecognizer *)recognizer
{
    if (self.highlightLineCurrentEnabled) {
        self.highlightLineCurrentEnabled = NO;
    }
    [self setNeedsDisplay];
}

/** 依据元素个数调整间距*/
- (void)adjustCandleMinWidth {
    self.candleMinWidth = self.contentWidth / self.dataSet.data.count;
}

/** 会调用两遍*/
- (void)notifyDataSetChanged
{
    [super notifyDataSetChanged];
    [self adjustCandleMinWidth];
    self.candleWidth = self.candleMinWidth;
    // 从起点绘制
    [self setNeedsDisplay];
    self.startDrawIndex = 0;
    // 调用layoutSubviews
}

- (void)notifyDeviceOrientationChanged
{
    [super notifyDeviceOrientationChanged];
    self.startDrawIndex = 0;
}

@end

//
//  YKLineChartView.h
//  YKLineChartView
//
//  Created by chenyk on 15/12/9.
//  Copyright © 2015年 chenyk. All rights reserved.
//  https://github.com/chenyk0317/YKLineChartView

#import "YKLineChartViewBase.h"

@class  YKLineDataSet;
@interface YKLineChartView : YKLineChartViewBase

/** 矩形块的默认宽度, 理解为比例尺*/
@property (nonatomic,assign)CGFloat candleWidth;
/** 矩形块的最大宽度*/
@property (nonatomic,assign)CGFloat candleMaxWidth;
/** 矩形块的最小宽度*/
@property (nonatomic,assign)CGFloat candleMinWidth;

@property (nonatomic,assign)BOOL isShowAvgMarkerEnabled;

@property (nonatomic,strong)NSDictionary * avgLabelAttributedDic;

- (void)adjustCandleMinWidth;

- (void)setupData:(YKLineDataSet *)dataSet;

- (void)addDataSetWithArray:(NSArray *)array;

@end

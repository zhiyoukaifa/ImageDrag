//
//  ViewController.m
//  ImageDrag
//
//  Created by 道道明明白白 on 2018/10/13.
//  Copyright © 2018年 道道明明白白. All rights reserved.
//

//zs20181014 参考链接https://github.com/Jethuang/HDragImageView
//可以将这个功能抽取出来   之后算坐标的时候 利用坐标系的转换 转换成相对于Window的坐标 进行统一化管理
//CGRect rect = [self.superview convertRect:self.frame toView:[UIApplication sharedApplication].keyWindow];


#import "ViewController.h"

#define width (self.view.frame.size.width / 3.0 - 4)


@interface ViewController ()


@property (nonatomic, strong) NSMutableArray *arrImages;   /**< zs20181013 图片数组  */

@property (nonatomic, strong) NSMutableArray *arrImageViews;   /**< zs20181013 imageView数组  */


@property (nonatomic, assign) CGPoint centerDrag;        /**< zs20181013 记录当前拖拽图片的的中心点  */

@property (nonatomic, assign) BOOL isDrag;       /**< zs20181013 是否可以拖拽  */

@property (nonatomic, strong) UIImageView *currentDragImageView;


@end

@implementation ViewController

- (void)viewDidLoad {
   
    [super viewDidLoad];
 
    [self addImages];

    _isDrag = YES;
}


#pragma mark - 添加图片布局 zs20181013
- (void)addImages
{
    _arrImageViews = [NSMutableArray arrayWithCapacity:0];
    for (int i = 0; i < self.arrImages.count; i ++) {
  
        UIImageView *imageView = [[UIImageView alloc] initWithImage:self.arrImages[i]];
        imageView.frame = CGRectMake(i%3 * width + i %3 * 6, i/3 * width + 44 + i/3 * 6, width, width);
        imageView.userInteractionEnabled = YES;//zs20181013 注意要设置成YES 否则手势不能响应
        imageView.tag = i;
        [self.view addSubview:imageView];
        [self addDragAction:imageView];
        [_arrImageViews addObject:imageView];
    }
}

#pragma mark - 添加拖拽方法
- (void)addDragAction:(UIView*)viewDrag
{
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDrag:)];
    [viewDrag addGestureRecognizer:pan];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickItem:)];
    [viewDrag addGestureRecognizer:tap];
    
}
- (void)panDrag:(UIPanGestureRecognizer *)pan
{

    CGPoint transP = [pan translationInView:self.view];
    UIImageView *imageViewDrag = (UIImageView *)pan.view;
    _currentDragImageView = imageViewDrag;

    if (pan.state == UIGestureRecognizerStateBegan) {
        
        _centerDrag = imageViewDrag.center;
    } else if (pan.state == UIGestureRecognizerStateChanged){
        imageViewDrag.alpha = 0.8;
        [self.view bringSubviewToFront:imageViewDrag];//zs20181013 将图片置为最外层
        CGPoint center = imageViewDrag.center;
        center.x += transP.x;
        center.y += transP.y;
        imageViewDrag.center = center;
        
        UIImageView *imageViewOther = [self imageViewCenterInImageViews:imageViewDrag];
        if (imageViewOther) {
              self.centerDrag = CGPointMake(imageViewOther.center.x, imageViewOther.center.y);
            NSLog(@"____%ld",(long)imageViewOther.tag);
            [self layoutImageViews:imageViewOther];
        }
      
    
    } else if(pan.state == UIGestureRecognizerStateEnded) {
        imageViewDrag.alpha = 1;
        [UIView animateWithDuration:0.2 animations:^{
            imageViewDrag.center = self.centerDrag;
        }];
    }
    //每次移动完，将移动量置为0，否则下次移动会加上这次移动量
    [pan setTranslation:CGPointMake(0, 0) inView:self.view];
}
- (void)clickItem:(UITapGestureRecognizer *)tap
{
     NSLog(@"点击");
}
//zs20181013 核心算法 看下当前按钮中心点在哪个按钮上
- (UIImageView *)imageViewCenterInImageViews:(UIImageView *)curImageView
{
    for (UIImageView *imageView in self.arrImageViews) {
        if (curImageView == imageView) continue;
        
        CGRect frame = imageView.frame;
        if (CGRectContainsPoint(frame, curImageView.center)) {
            return imageView;
        }
    }
    return nil;
}
- (void)layoutImageViews:(UIImageView*)imageView
{
    NSInteger tag = imageView.tag;
    if (_currentDragImageView.tag > imageView.tag) {
        
        for (NSUInteger i = imageView.tag;  i < _currentDragImageView.tag; i ++) {
            
            UIImageView *imageViewOne = self.arrImageViews[i];
            imageViewOne.tag = imageViewOne.tag + 1;
            
            [UIView animateWithDuration:0.2 animations:^{
                
                imageViewOne.frame = CGRectMake((i+1)%3 * width + (i+1)%3 * 6, (i+1)/3 * width + 44 + (i+1)/3 * 6, width, width);
            }];
        }
        _currentDragImageView.tag = tag;
        
         [self sortImageViewWithTag];
        return;
    }
    
    if (_currentDragImageView.tag < imageView.tag) {
        

        for (NSUInteger i = _currentDragImageView.tag + 1;  i < imageView.tag + 1; i ++) {
            
            UIImageView *imageViewOne = self.arrImageViews[i];
            imageViewOne.tag = imageViewOne.tag - 1;

            [UIView animateWithDuration:0.2 animations:^{

               imageViewOne.frame = CGRectMake((i-1)%3 * width + (i-1)%3 * 6, (i-1)/3 * width + 44 + (i-1)/3 * 6, width, width);
            }];
        }
        _currentDragImageView.tag = tag;
        
        //zs20181013 数组中 图片进行排序
        [self sortImageViewWithTag];
    }
    
    
}

- (void)sortImageViewWithTag
{
    for (int i = 0; i < self.arrImageViews.count; i ++){
        
        for (int j = 0; j < self.arrImageViews.count - i - 1; j ++){
            
            UIImageView *imageView0 = self.arrImageViews[j];
            UIImageView *imageView1 = self.arrImageViews[j + 1];
            
            if (imageView0.tag > imageView1.tag ) {
                
                self.arrImageViews[j] =imageView1;
                self.arrImageViews[j + 1] = imageView0;
            }
        }
    }
    
    for (int i = 0; i < self.arrImageViews.count; i++) {
        
        UIImageView  *imageView = self.arrImageViews[i];
         NSLog(@"tag ___%ld",imageView.tag);
    }
    
}



#pragma mark - getter

- (NSMutableArray *)arrImages
{
    if (_arrImages == nil) {
        
        _arrImages = [NSMutableArray arrayWithCapacity:0];
        for (int i = 0;  i < 9; i ++) {
            UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg",i]];
            [_arrImages addObject:image];
        }
        
    }
    return _arrImages;
}








@end

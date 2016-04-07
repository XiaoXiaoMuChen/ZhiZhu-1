//
//  fastTextView_DemoViewController.m
//  fastTextView_Demo
//
//  Created by Devin Doty on 4/18/11.
//  Copyright 2011 enormfast. All rights reserved.
//

#import "DemoViewController.h"
#import "FastTextView.h"

#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>
//#import "ImageAttachmentCell.h"
#import "SlideAttachmentCell.h"
#import "EmotionAttachmentCell.h"
#import <CoreText/CoreText.h>
#import "UIImage-Extensions.h"
#import "NSAttributedString+TextUtil.h"
#import "TextConfig.h"

#define NAVBAR_HEIGHT 44.0f
#define TABBAR_HEIGHT 49.0f
#define STATUS_HEIGHT 20.0f

#define TOP_VIEW_HEIGHT 33.0f
#define TOP_VIEW_WIDTH 48.0f

#define ARRSIZE(a)      (sizeof(a) / sizeof(a[0]))

#define ios7 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)

@interface DemoViewController() <FastTextViewDelegate,MBProgressHUDDelegate>
{
    //    UITextView *_aswQueTextView;
    UIButton *_itemBtn;
    NSString *_placeStr;
    MBProgressHUD *HUD;
    RRMessageModel *_modelMessage;
}
@property (nonatomic, strong) UIButton *buttonAddPhoto;
@property (nonatomic, strong) UISwitch *imageSwitch;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) NSMutableArray *photosThumbnailLibrairy;
@property (nonatomic, strong) NSMutableArray *selectedPhotos;
@property (nonatomic, strong) NSMutableArray *imageNameArray;
@property (nonatomic, strong) NSMutableArray *alAssetArray;
@property (nonatomic, strong) NSMutableArray *contentArray;
@property (nonatomic, strong) NSMutableAttributedString *attrStr;
@property (nonatomic, strong) UICollectionView *photosCollection;
@property (nonatomic, assign) BOOL state;
@property (nonatomic, assign) BOOL isHight;

@property (nonatomic, strong) void (^completion)(RRMessageModel *model, BOOL isCancel);
@end

@implementation DemoViewController
{
    FastTextView *_fastTextView;
    UITextView *_textView;
    BOOL isAddSlide;
    UIPageControl *pageControl;
    UIScrollView *scrollView;
    CGFloat origin_y;
    NSMutableAttributedString *mutableAttributedString;
}

@synthesize fastTextView=_fastTextView;
@synthesize textView=_textView;
@synthesize topview;


#pragma mark -
#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.automaticallyAdjustsScrollViewInsets = NO;
    
    if(ios7){
        origin_y= NAVBAR_HEIGHT+STATUS_HEIGHT;
    }else{
        origin_y=0;
    }
    
    _selectedPhotos = [[NSMutableArray alloc] init];
    self.photosThumbnailLibrairy = [[NSMutableArray alloc] init];
    
    self.title = @"回答问题";
    _alAssetArray = [NSMutableArray array];
    
    [self createBarbuttonItem];
    
    if (_fastTextView==nil) {
        
        FastTextView *view = [[FastTextView alloc] initWithFrame:CGRectMake(0, origin_y , SCREEN_WIDTH, SCREEN_HEIGHT - origin_y)];

        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        view.attributeConfig=[TextConfig editorAttributeConfig];
        view.delegate = (id<FastTextViewDelegate>)self;
        [view setFont:[UIFont systemFontOfSize:13]];
        view.pragraghSpaceHeight=3;
        view.backgroundColor=[UIColor clearColor];
        
        [self.view addSubview:view];
        self.fastTextView = view;
        _fastTextView.contentSize = CGSizeMake(SCREEN_WIDTH, view.bounds.size.height);
        _fastTextView.delegate = (id<FastTextViewDelegate>)self;
        
        NSMutableAttributedString *parseStr=[[NSMutableAttributedString alloc]init];
        [parseStr addAttributes:[self defaultAttributes] range:NSMakeRange(0, [parseStr length])];
        self.fastTextView.attributedString=parseStr;
        self.fastTextView.keyboardType = UIKeyboardTypeDefault;
        self.fastTextView.returnKeyType = UIReturnKeyDone;
        
        [self.fastTextView becomeFirstResponder];
        self.view.backgroundColor=[UIColor whiteColor];
        
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

}


# pragma mark Deltegate 发布内容和图片
- (void) postMessage1 {
    
    _contentArray = [NSMutableArray array];
    NSString *attrString = _fastTextView.text;
    NSArray *array = [attrString componentsSeparatedByString:@"\n"];
    for (NSString *str in array) {
        if (str.length > 1) {
//            NSString *answerContent = [NSString stringWithFormat:@"<p>%@</p>",str];
//            [_contentArray addObject:answerContent];
            [_contentArray addObject:str];
        }
    }
    
    mutableAttributedString=[_fastTextView.attributedString mutableCopy];

    NSRange range = NSMakeRange(0, mutableAttributedString.length);
    long int i = 1;
    int flag = 0;
    int num = 0;
    BOOL isText = NO;
    BOOL isImage = NO;
    NSArray *dataArr = [NSArray arrayWithArray:_contentArray];
    NSDictionary *dicAttr = [mutableAttributedString attributesAtIndex:0 effectiveRange:&range];
    while (dicAttr) {
        
        SlideAttachmentCell *imageCell = [mutableAttributedString attribute:FastTextAttachmentAttributeName atIndex:i effectiveRange:&range];
        if (imageCell) {
            [_selectedPhotos addObject:imageCell.cellImage];
            
            if (flag < _contentArray.count) {
                [_contentArray insertObject:@"MC_cellImage" atIndex:flag];
            }else{
                [_contentArray addObject:@"MC_cellImage"];
            }
//            if (isImage) {
//                i = i + 2;
//            }
            i = i + 3;
            isImage = YES;
            isText = NO;
        }else{
            NSString *string = @"";
            if (num < dataArr.count) {
                string = dataArr[num];
                num ++;
            }else{
                break;
            }
            if (isText) {
                i = i + 2;
            }
            i = i + string.length;
            isImage = NO;
            isText = YES;
        }
        flag ++;
        if (i >= mutableAttributedString.length) {
            break;
        }
        range = NSMakeRange(0, MAXFLOAT);
        dicAttr = [mutableAttributedString attributesAtIndex:i effectiveRange:&range];
        NSLog(@"********************%@",mutableAttributedString.mutableString);
    
    }
    
    if (_selectedPhotos.count > 0) {
        [self updateImages];
    }else{
        [self updateAnswer];
    }
    
}

- (void) postMessage {
    
//    _contentArray = [NSMutableArray array];
//    NSString *attrString = _fastTextView.text;
//    NSArray *array = [attrString componentsSeparatedByString:@"\n"];
//    for (NSString *str in array) {
//        if (str.length > 1) {
//            //            NSString *answerContent = [NSString stringWithFormat:@"<p>%@</p>",str];
//            //            [_contentArray addObject:answerContent];
//            [_contentArray addObject:str];
//        }
//    }
    
    NSRange range = NSMakeRange(0, mutableAttributedString.length);
    NSDictionary *dicAttr = [mutableAttributedString attributesAtIndex:0 effectiveRange:&range];
    mutableAttributedString=[_fastTextView.attributedString mutableCopy];
    NSMutableString *addString = [NSMutableString string];
    
    NSMutableArray *array = (NSMutableArray *)[mutableAttributedString.mutableString componentsSeparatedByString:@"\n"];
    for (int j = 0; j < array.count; j ++) {
        NSString *str = array[j];
        if ([array[j] isEqualToString:@"\U0000fffc"]) {
            SlideAttachmentCell *imageCell = [mutableAttributedString attribute:FastTextAttachmentAttributeName atIndex:addString.length effectiveRange:&range];
            if (imageCell) {
                [_selectedPhotos addObject:imageCell.cellImage];
            }
        }
        [addString appendFormat:@"%@\n",str];
    }
    
 
    if (_selectedPhotos.count > 0) {
        [self updateImages];
    }else{
        [self updateAnswer];
    }
    
    
}



- (void) cancelMessage {
    if ([self.delegate respondsToSelector:@selector(messageCancel)]) {
        [self.delegate messageCancel];
    }
    
    if (self.completion != nil) {
        self.completion(nil, true);
    }
}


/**
 *  上传图片
 */
-(void)updateImages
{
    CGFloat ratio;
//    if (_isHight) {
//        ratio = 1.0;
//    }else{
//        ratio = 0.5;
//    }
    ratio = 1.0;
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"refRelationCategory"] = @"INFO_FAQS_ANSWER";
    params[@"name"] = @".jpg";
    [MCNetworkingLogin startMultiPartUploadTaskWithURL:addQuestionImgsUrlString imagesArray:_selectedPhotos parameterOfimages:_quesModel.mcId parametersDict:params compressionRatio:ratio succeedBlock:^(id operation, id responseObject) {
        
        NSDictionary *responseObjects = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        
        NSString *status = [responseObjects objectForKey:@"status"];
        //        NSString *errorMessage = [responseObjects objectForKey:@"errorMessage"];
        
        if (status.intValue == 200) {
            _imageNameArray = [NSMutableArray array];
            _imageNameArray = [responseObjects objectForKey:@"resultObject"];
            
            [self updateAnswer];
        }
        
    } failedBlock:^(id operation, NSError *error) {
        
        NSLog(@"**********     %@",error);
        
    } uploadProgressBlock:^(float uploadPercent, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        
        
    }];
}

/**
 *  提交回答内容
 */
-(void)updateAnswer
{
    HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:HUD];
    
    HUD.delegate = self;
    HUD.labelText = @"正在提交...";
    [HUD show:YES];
    
    NSMutableArray *imageArr = [NSMutableArray array];
    if (_imageNameArray && _imageNameArray.count > 0) {
        
        for (int i = 0; i < _imageNameArray.count; i ++) {
            NSString *imageStr = [NSString stringWithFormat:@"<p><img src=\"%@\"/></p>",_imageNameArray[i]];
            [imageArr addObject:imageStr];
        }
    }
    
//    int k = 0;
//    for (int j = 0; j < _contentArray.count; j ++) {
//        NSString *str = _contentArray[j];
//        if ([str isEqualToString:@"MC_cellImage"]) {
//            if (k < imageArr.count) {
//                [_contentArray replaceObjectAtIndex:j withObject:imageArr[k]];
//                k ++;
//            }
//        }else{
//            NSString *answerContent = [NSString stringWithFormat:@"<p>%@</p>",_contentArray[j]];
//            [_contentArray replaceObjectAtIndex:j withObject:answerContent];
//        }
//    }
//    
//    NSString *answerString = [_contentArray componentsJoinedByString:@""];
    
    
    _contentArray = [NSMutableArray array];
//    mutableAttributedString=[_fastTextView.attributedString mutableCopy];
    
    NSMutableArray *array = (NSMutableArray *)[mutableAttributedString.mutableString componentsSeparatedByString:@"\n"];
    
    int k = 0;
    for (int j = 0; j < array.count; j ++) {
        NSString *str = array[j];
        NSLog(@"%@",str);
        if ([str isEqualToString:@"\U0000fffc"]) {
            if (k < imageArr.count) {
                [array replaceObjectAtIndex:j withObject:imageArr[k]];
                k ++;
            }
        }else{
            NSString *answerStr = [NSString stringWithFormat:@"<p>%@</p>",str];
            [array replaceObjectAtIndex:j withObject:answerStr];
        }
    }

    NSString *answerString = [array componentsJoinedByString:@""];
    
    
    //封装推荐请求参数
    NSMutableDictionary *putParams = [NSMutableDictionary dictionary];
    putParams[@"answerContent"] = answerString;
    putParams[@"infoFaqsQuestionId"] = _quesModel.mcId;
    putParams[@"infoConstructionCategoryId"] = _quesModel.infoConstructionCategoryId;
    putParams[@"answerIntro"] = _textView.text;
    
    [MCNetworkingLogin postLogin:addAnswerUrlString parameters:putParams success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSString *errorMessage = responseObject[@"errorMessage"];
        NSString *status = responseObject[@"status"];
        
        HUD.mode = MBProgressHUDModeText;
        if (status.intValue == 200) {
            HUD.labelText = @"提交成功";
  
            self.completion(nil, false);
            
            //创建一个消息对象
            NSNotification * notice = [NSNotification notificationWithName:@"answerSuccess" object:nil userInfo:@{@"status":@"success"}];
            //发送消息
            [[NSNotificationCenter defaultCenter] postNotification:notice];

            [self.navigationController popViewControllerAnimated:YES];
        }else if(status.intValue == 512 && [errorMessage isEqualToString:@"回答内容不能为空，并且长度小于3000"]){
            HUD.labelText = @"回答内容不能为空，并且长度小于3000";
        }else if (status.intValue == 512 && [errorMessage isEqualToString:@"您已经回答过此问题了"]){
            HUD.labelText = @"您已经回答过此问题了";
        }
        [HUD hide:YES afterDelay:1];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        HUD.labelText = @"提交失败";
        [HUD hide:YES afterDelay:1];
    }];
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    
}


- (void) presentController:(UIViewController *)parentController :(void (^)(RRMessageModel *model, BOOL isCancel))completion {

    CATransition *transition = [CATransition animation];
    transition.duration = 1.0f;
    transition.timingFunction = UIViewAnimationCurveEaseInOut;
    transition.fillMode = kCAFillModeForwards;
    transition.type = @"charminUltra";
    transition.subtype = kCATransitionFromTop;
    transition.delegate = self;
    [parentController.view.window.layer addAnimation:transition forKey:nil];
    
    [parentController.navigationController pushViewController:self animated:YES];
    

    self.completion = completion;
}

- (ALAssetsLibrary *) defaultAssetLibrairy {
    static ALAssetsLibrary *assetLibrairy;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        assetLibrairy = [[ALAssetsLibrary alloc] init];
    });
    return (assetLibrairy);
}

- (BOOL) shouldAutorotate {
    return (false);
}
/**
 *  创建BarItem
 */
- (void)createBarbuttonItem{
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    UIBarButtonItem *cancelBtnItem = [[UIBarButtonItem alloc]initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(Cancel)];
    self.navigationItem.leftBarButtonItem = cancelBtnItem;
    
    _itemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _itemBtn.frame = CGRectMake(0, 0, 48.5, 23.5);
    _itemBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    _itemBtn.layer.borderWidth = 0.5;
    _itemBtn.layer.cornerRadius = 3;
    [_itemBtn setTitle:@"发布" forState:UIControlStateNormal];
    _itemBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    _itemBtn.enabled = NO;
    [_itemBtn addTarget:self action:@selector(postMessage) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *releaseBtnItem = [[UIBarButtonItem alloc]initWithCustomView:_itemBtn];
    
    self.navigationItem.rightBarButtonItem = releaseBtnItem;
}

//返回上一页
- (void)Cancel{
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark UITextViewDelegate
-(BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if ([_textView.text isEqualToString:_placeStr]) {
        _textView.textColor = [UIColor blackColor];
        _textView.text = @"";
    }
    
    return YES;
}


-(NSDictionary *)defaultAttributes{
    
    NSString *fontName = @"Helvetica";
    CGFloat fontSize= 17.0f;
    UIColor *color = [UIColor blackColor];
    //UIColor *strokeColor = [UIColor whiteColor];
    //CGFloat strokeWidth = 0.0;
    CGFloat paragraphSpacing = 0.0;
    CGFloat lineSpacing = 0.0;
    //CGFloat minimumLineHeight=24.0f;
    
    
    CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)fontName,
                                             fontSize, NULL);
    
    CTParagraphStyleSetting settings[] = {
        { kCTParagraphStyleSpecifierParagraphSpacing, sizeof(CGFloat), &paragraphSpacing },
        { kCTParagraphStyleSpecifierLineSpacing, sizeof(CGFloat), &lineSpacing },
        // { kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(CGFloat), &minimumLineHeight },
    };
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings, ARRSIZE(settings));

    NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           (id)color.CGColor, kCTForegroundColorAttributeName,
                           (__bridge id)fontRef, kCTFontAttributeName,
                           //(id)strokeColor.CGColor, (NSString *) kCTStrokeColorAttributeName,
//                           (id)[NSNumber numberWithFloat: strokeWidth], (NSString *)kCTStrokeWidthAttributeName,
                           //(__bridge id) paragraphStyle, (NSString *) kCTParagraphStyleAttributeName,
                           nil];
    
    CFRelease(fontRef);
    return attrs;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


#pragma mark -
#pragma mark fastTextViewDelegate

- (BOOL)fastTextViewShouldBeginEditing:(FastTextView *)textView {
    return YES;
}

- (BOOL)fastTextViewShouldEndEditing:(FastTextView *)textView {

    return YES;
}

- (void)fastTextViewDidBeginEditing:(FastTextView *)textView {
    if (textView.text.length >= 1) {
        [_itemBtn setBackgroundColor:MCColor(30, 181, 128, 1.0)];
        _itemBtn.enabled = YES;
    }else{
        [_itemBtn setBackgroundColor:[UIColor clearColor]];
        _itemBtn.enabled = NO;
    }
}

- (void)fastTextViewDidEndEditing:(FastTextView *)textView {

}

- (void)fastTextViewDidChange:(FastTextView *)textView {
    
}

- (void)fastTextView:(FastTextView*)textView didSelectURL:(NSURL *)URL {
        
}


- (IBAction)attachSlide:(id)sender;
{

    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    isAddSlide=true;
    [self presentModalViewController:picker animated:YES];

}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate

- (void)_addAttachmentFromAsset:(ALAsset *)asset;
{
    ALAssetRepresentation *rep = [asset defaultRepresentation];
    NSMutableData *data = [NSMutableData dataWithLength:[rep size]];
    
    NSError *error = nil;
    if ([rep getBytes:[data mutableBytes] fromOffset:0 length:[rep size] error:&error] == 0) {
        NSLog(@"error getting asset data %@", [error debugDescription]);
    } else {

        UIImage *img=[UIImage imageWithData:data];
        
        NSString *newfilename=[NSAttributedString scanAttachmentsForNewFileName:_fastTextView.attributedString];
        
     
        
        NSArray *_paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString * _documentDirectory = [[NSString alloc] initWithString:[_paths objectAtIndex:0]];
        
        
        UIImage *thumbimg=[img imageByScalingProportionallyToSize:CGSizeMake(1024,6000)];
        
        NSString *pngPath=[_documentDirectory stringByAppendingPathComponent:newfilename];
        
        //[[AppDelegate documentDirectory] stringByAppendingPathComponent:@"tmp.jpg"];
        
        
        [UIImageJPEGRepresentation(thumbimg,1.0)writeToFile:pngPath atomically:YES];
                
        UITextRange *selectedTextRange = [_fastTextView selectedTextRange];
        if (!selectedTextRange) {
            UITextPosition *endOfDocument = [_fastTextView endOfDocument];
            selectedTextRange = [_fastTextView textRangeFromPosition:endOfDocument toPosition:endOfDocument];
        }
        UITextPosition *startPosition = [selectedTextRange start] ; // hold onto this since the edit will drop
        
        unichar attachmentCharacter = FastTextAttachmentCharacter;
        [_fastTextView replaceRange:selectedTextRange withText:[NSString stringWithFormat:@"\n%@\n",[NSString stringWithCharacters:&attachmentCharacter length:1]]];
            
        startPosition=[_fastTextView positionFromPosition:startPosition inDirection:UITextLayoutDirectionRight offset:1];
        UITextPosition *endPosition = [_fastTextView positionFromPosition:startPosition offset:1];
        selectedTextRange = [_fastTextView textRangeFromPosition:startPosition toPosition:endPosition];
    
        NSLog(@"_______________   %@",_fastTextView.attributedString);
        mutableAttributedString=[_fastTextView.attributedString mutableCopy];
    
        NSUInteger st = ((FastIndexedPosition *)(selectedTextRange.start)).index;
        NSUInteger en = ((FastIndexedPosition *)(selectedTextRange.end)).index;
        
        if (en < st) {
            return;
        }
        NSUInteger contentLength = [[_fastTextView.attributedString string] length];
        if (en > contentLength) {
            en = contentLength; // but let's not crash
        }
        if (st > en)
            st = en;
        NSRange cr = [[_fastTextView.attributedString string] rangeOfComposedCharacterSequencesForRange:(NSRange){ st, en - st }];
        if (cr.location + cr.length > contentLength) {
            cr.length = ( contentLength - cr.location ); // but let's not crash
        }
               
        if(isAddSlide){
            
            FileWrapperObject *fileWp = [[FileWrapperObject alloc] init];
            [fileWp setFileName:newfilename];
            [fileWp setFilePath:pngPath];
            
            SlideAttachmentCell *cell = [[SlideAttachmentCell alloc] initWithFileWrapperObject:fileWp] ;
            //ImageAttachmentCell *cell = [[ImageAttachmentCell alloc] init];
            cell.isNeedThumb=TRUE;
            
            float scale = thumbimg.size.width*1.0/(SCREEN_WIDTH - 24);
            cell.thumbImageWidth=SCREEN_WIDTH - 24;
            cell.thumbImageHeight=thumbimg.size.height/scale;
//            cell.txtdesc=@"幻灯片测试";
            
            thumbimg = [thumbimg scaleToSize:thumbimg size:CGSizeMake(cell.thumbImageWidth, cell.thumbImageHeight)];
            cell.cellImage = thumbimg;
            
            [mutableAttributedString addAttribute: FastTextAttachmentAttributeName value:cell  range:cr];
            
            NSRange range = NSMakeRange(0, MAXFLOAT);
            NSDictionary *dict = [mutableAttributedString attributesAtIndex:1 effectiveRange:&range];
            
            SlideAttachmentCell *imageCell = [mutableAttributedString attribute:FastTextAttachmentAttributeName atIndex:1 effectiveRange:&range];
            
            NSMutableArray *stringArray = [NSMutableArray array];
            NSArray *array = [_fastTextView.text componentsSeparatedByString:@"\n"];
            for (NSString *str in array) {
                if (str.length > 1) {
                    [stringArray addObject:str];
                }
            }
            
            [_fastTextView setFrame:CGRectMake(0, origin_y , SCREEN_WIDTH+10, SCREEN_HEIGHT - origin_y)];
//            _fastTextView.contentSize = CGSizeMake(SCREEN_WIDTH-20, _fastTextView.bounds.size.height);
            [_fastTextView becomeFirstResponder];


            [_fastTextView setContentOffset:CGPointMake(0, contentLength + thumbimg.size.height + 80) animated:YES];
        }else{
//            ImageAttachmentCell *cell = [[ImageAttachmentCell alloc] initWithFileWrapper:wrapper];
//            //ImageAttachmentCell *cell = [[ImageAttachmentCell alloc] init];
//            cell.isNeedThumb=TRUE;
//            cell.thumbImageWidth=200.0f;
//            cell.thumbImageHeight=200.0f;
//
//            [mutableAttributedString addAttribute: fastTextAttachmentAttributeName value:cell  range:cr];
        }
        
        if (mutableAttributedString) {
            _fastTextView.attributedString = mutableAttributedString;
        }
 
        
    }
}



- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init] ;
    [library assetForURL:[info objectForKey:UIImagePickerControllerReferenceURL]
             resultBlock:^(ALAsset *asset){
                 // This get called asynchronously (possibly after a permissions question to the user).
                 [self _addAttachmentFromAsset:asset];
             }
            failureBlock:^(NSError *error){
                NSLog(@"error finding asset %@", [error debugDescription]);
            }];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker;
{
    [self dismissModalViewControllerAnimated:YES];
}


- (void)_addEmotion:(NSString *)emotionImgName;
{
    
    UITextRange *selectedTextRange = [_fastTextView selectedTextRange];
    if (!selectedTextRange) {
        UITextPosition *endOfDocument = [_fastTextView endOfDocument];
        selectedTextRange = [_fastTextView textRangeFromPosition:endOfDocument toPosition:endOfDocument];
    }
    UITextPosition *startPosition = [selectedTextRange start] ; // hold onto this since the edit will drop
    
    unichar attachmentCharacter = FastTextAttachmentCharacter;
    [_fastTextView replaceRange:selectedTextRange withText:[NSString stringWithFormat:@"%@",[NSString stringWithCharacters:&attachmentCharacter length:1]]];
    
//    startPosition=[_fastTextView positionFromPosition:startPosition inDirection:UITextLayoutDirectionRight offset:1];
    UITextPosition *endPosition = [_fastTextView positionFromPosition:startPosition offset:1];
    selectedTextRange = [_fastTextView textRangeFromPosition:startPosition toPosition:endPosition];
    
    
    NSMutableAttributedString *mutableAttributedString=[_fastTextView.attributedString mutableCopy];
    
    NSUInteger st = ((FastIndexedPosition *)(selectedTextRange.start)).index;
    NSUInteger en = ((FastIndexedPosition *)(selectedTextRange.end)).index;
    
    if (en < st) {
        return;
    }
    NSUInteger contentLength = [[_fastTextView.attributedString string] length];
    if (en > contentLength) {
        en = contentLength; // but let's not crash
    }
    if (st > en)
        st = en;
    NSRange cr = [[_fastTextView.attributedString string] rangeOfComposedCharacterSequencesForRange:(NSRange){ st, en - st }];
    if (cr.location + cr.length > contentLength) {
        cr.length = ( contentLength - cr.location ); // but let's not crash
    }
    
    FileWrapperObject *fileWp = [[FileWrapperObject alloc] init];
    [fileWp setFileName:emotionImgName];
    [fileWp setFilePath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:emotionImgName]];
    EmotionAttachmentCell *cell = [[EmotionAttachmentCell alloc] initWithFileWrapperObject:fileWp] ;
    [mutableAttributedString addAttribute: FastTextAttachmentAttributeName value:cell  range:cr];
    
    if (mutableAttributedString) {
        _fastTextView.attributedString = mutableAttributedString;
    }
}



#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    _textView=nil;
    _fastTextView=nil;
}

- (void)dealloc {
    _textView=nil;
    _fastTextView=nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}


#pragma mark Removing toolbar

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary* info = [notification userInfo];
    CGSize keyBoardSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    self.fastTextView.frame = CGRectMake(self.fastTextView.frame.origin.x, origin_y, self.fastTextView.frame.size.width,self.view.bounds.size.height -origin_y - keyBoardSize.height-TOP_VIEW_HEIGHT );
    
    self.topview.frame = CGRectMake(0, self.fastTextView.frame.origin.y+ self.fastTextView.frame.size.height, self.fastTextView.frame.size.width, TOP_VIEW_HEIGHT);
    
    [self.view addSubview:self.topview];
    [self.view bringSubviewToFront:self.topview];
    

}

- (void)keyboardWillHide:(NSNotification *)notification{
    self.fastTextView.frame = CGRectMake(self.fastTextView.frame.origin.x, origin_y, self.fastTextView.frame.size.width, self.view.bounds.size.height-origin_y);
    
    [self.topview removeFromSuperview];

}

-(IBAction)dismissKeyBoard:(id)sender {
    [_fastTextView resignFirstResponder];
}

-(IBAction)bold:(id)sender {
    if (_fastTextView.selectedRange.length>0) {
        CTFontRef font = CTFontCreateWithName((CFStringRef)[UIFont boldSystemFontOfSize:17].fontName, 17, NULL);
        [_fastTextView.attributedString beginStorageEditing];
        [_fastTextView.attributedString addAttribute:(id)kCTFontAttributeName value:(__bridge id)font range:_fastTextView.selectedRange];
        [_fastTextView.attributedString refreshParagraghInRange:_fastTextView.selectedRange];
        [_fastTextView.attributedString endStorageEditing];
        [_fastTextView refreshAllView];
    }
}

-(IBAction)italic:(id)sender {
    if (_fastTextView.selectedRange.length>0) {
        CTFontRef font = CTFontCreateWithName((CFStringRef)[UIFont italicSystemFontOfSize:17].fontName, 17, NULL);
        
        [_fastTextView.attributedString beginStorageEditing];
        [_fastTextView.attributedString addAttribute:(id)kCTFontAttributeName value:(__bridge id)font range:_fastTextView.selectedRange];
        [_fastTextView.attributedString refreshParagraghInRange:_fastTextView.selectedRange];
        [_fastTextView.attributedString endStorageEditing];
        [_fastTextView refreshAllView];
    }
}

-(IBAction)underline:(id)sender {
    if (_fastTextView.selectedRange.length>0) {
        CTFontRef font = CTFontCreateWithName((CFStringRef)[UIFont systemFontOfSize:17].fontName, 17, NULL);
        [_fastTextView.attributedString beginStorageEditing];
        [_fastTextView.attributedString addAttribute:(id)kCTFontAttributeName value:(__bridge id)font range:_fastTextView.selectedRange];
        
        //下划线
        [_fastTextView.attributedString addAttribute:(id)kCTUnderlineStyleAttributeName value:(id)[NSNumber numberWithInt:kCTUnderlineStyleThick] range:_fastTextView.selectedRange];
        //下划线颜色
        [_fastTextView.attributedString addAttribute:(id)kCTUnderlineColorAttributeName value:(id)[UIColor redColor].CGColor range:_fastTextView.selectedRange];
        
        [_fastTextView.attributedString refreshParagraghInRange:_fastTextView.selectedRange];
        [_fastTextView.attributedString endStorageEditing];
        [_fastTextView refreshAllView];
    }
}

-(IBAction)showFace:(UIButton*)sender
{
	sender.tag=!sender.tag;
	if (sender.tag) {
		[_fastTextView resignFirstResponder];
        UIView *inputView=[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 200)];
        [inputView setBackgroundColor:[UIColor grayColor]];
        
		scrollView=[[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 320, 180)];
        [scrollView setBackgroundColor:[UIColor grayColor]];
		for (int i=0; i<3; i++) {
			FacialView *fview=[[FacialView alloc] initWithFrame:CGRectMake(320*i, 0, 320, 180)];
			[fview loadFacialView:i size:CGSizeMake(45, 45)];
			fview.delegate=self;
			[scrollView addSubview:fview];
			
		}
		scrollView.contentSize=CGSizeMake(320*3, 180);
        scrollView.showsVerticalScrollIndicator  = NO;
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.scrollEnabled = YES;
        scrollView.pagingEnabled=YES;
        scrollView.delegate = self;
        
        //定义PageControll
        pageControl = [[UIPageControl alloc] init];
        [pageControl setBackgroundColor:[UIColor grayColor]];
        pageControl.frame = CGRectMake(130, 180, 60, 20);//指定位置大小
        pageControl.numberOfPages = 3;//指定页面个数
        pageControl.currentPage = 0;//指定pagecontroll的值，默认选中的小白点（第一个）
        [pageControl addTarget:self action:@selector(changePage:) forControlEvents:UIControlEventValueChanged];
        //添加委托方法，当点击小白点就执行此方法
        [inputView addSubview:scrollView];
        [inputView addSubview:pageControl];
        
        _fastTextView.inputView=inputView;
		[_fastTextView becomeFirstResponder];
        //		[scrollView release];
        //        [pageControl release];
        //[buttonFace setBackgroundImage:[UIImage imageNamed:@"btn_comment_keyboard"] forState:UIControlStateNormal];
        // NSLog(@"self.frame.size.height %f",self.frame.size.height);
		
	}else {
		_fastTextView.inputView=nil;
        
		[_fastTextView reloadInputViews];
		[_fastTextView becomeFirstResponder];
        //[buttonFace setBackgroundImage:[UIImage imageNamed:@"btn_comment_face"] forState:UIControlStateNormal];
	}
    
}

//scrollview的委托方法，当滚动时执行
- (void)scrollViewDidScroll:(UIScrollView *)sender {
    int page = scrollView.contentOffset.x / 320;//通过滚动的偏移量来判断目前页面所对应的小白点
    pageControl.currentPage = page;//pagecontroll响应值的变化
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
}

//pagecontroll的委托方法
- (IBAction)changePage:(id)sender {
    int page = pageControl.currentPage;//获取当前pagecontroll的值
    [scrollView setContentOffset:CGPointMake(320 * page, 0)];//根据pagecontroll的值来改变scrollview的滚动位置，以此切换到指定的页面
}



-(void)selectedFacialView:(NSString*)str
{
    
    [self _addEmotion:str];
    //NSLog(@"selectedFacialView %@",str);
    /*
    NSString *i_transCharacter = [m_pEmojiDic objectForKey:[NSString stringWithFormat:@"%@",str]];
	//判断输入框是否有内容，追加转义字符
	if (textView.text == nil) {
		self.textView.text = i_transCharacter;
	}
	else {
		self.textView.text = [textView.text stringByAppendingString:i_transCharacter];
	}
    */
	
}



@end

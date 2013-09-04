//
//  AlarmViewController.m
//  Alarm
//
//  Created by Masaki Hirokawa on 2013/09/04.
//  Copyright (c) 2013 Masaki Hirokawa. All rights reserved.
//

#import "AlarmViewController.h"

@interface AlarmViewController ()

@property UIButton      *startAlarmButton; //アラーム停止ボタン
@property UIButton      *stopAlarmButton;  //アラーム停止ボタン
@property UILabel       *wakeUpTimeLabel;  //起床時間の表示ラベル
@property AVAudioPlayer *alarmPlayer;      //アラームプレイヤー
@property UIDatePicker  *alarmPicker;      //起床時間の選択ピッカー
@property NSTimer       *alarmTimer;       //アラームタイマー
@property BOOL          isStartedAlarm;    //アラーム開始フラグ

@end

@implementation AlarmViewController

typedef enum alarmEventType : NSUInteger {
    ALARM_START = 1,
    ALARM_STOP  = 2
} alarmEventType;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    //背景指定
    self.view.backgroundColor = [UIColor underPageBackgroundColor];
    
    //アラームプレイヤー初期化
    [self initAlarmPlayer];
    
    //起床時間の表示ビュー配置
    [self setWakeUpTimeView];
    
    //アラーム開始ボタン配置
    [self setAlarmControlButton:ALARM_START];
    
    //起床時間の選択ピッカー配置
    [self setWakeUpTimePicker];
}

#pragma mark alarm player

//アラームプレイヤー初期化
- (void)initAlarmPlayer
{
    _alarmPlayer = [[DCAudioPlayer alloc] initWithAudio:ALARM_NAME ext:ALARM_FILE_EXT isUseDelegate:NO];
}

#pragma mark wake up time label

//起床時間の表示ビュー配置
- (void)setWakeUpTimeView
{
    UIView *wakeUpTimeView = [[UIView alloc] initWithFrame:WAKE_UP_TIME_RECT];
    wakeUpTimeView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.5f];
    
    //起床時間のラベル配置
    _wakeUpTimeLabel = [DCLabel planeLabel:WAKE_UP_TIME_RECT
                                      text:wakeUpTime font:WAKE_UP_TIME_LABEL_FONT
                                 textColor:[UIColor whiteColor] textAlignment:NSTextAlignmentCenter
                           backgroundColor:[UIColor clearColor]];
    [wakeUpTimeView addSubview:_wakeUpTimeLabel];
    
    [self.view addSubview:wakeUpTimeView];
}

//起床時間のラベル更新
- (void)updateWakeUpTimeLabel:(NSString *)timeText
{
    _wakeUpTimeLabel.text = timeText;
    
    //userDefaults更新
    [userDefaults setObject:_wakeUpTimeLabel.text forKey:UD_WAKE_UP_TIME_KEY];
    [userDefaults synchronize];
}

#pragma mark alarm control button

//アラームコントロールボタン配置
- (void)setAlarmControlButton:(NSUInteger)tag
{
    //ボタン生成
    UIButton *alarmControlButton = [DCButton planeButton:CGRectMake(self.view.center.x - (ALARM_CTR_BTN_WIDTH / 2), ALARM_CTR_BTN_Y, ALARM_CTR_BTN_WIDTH, ALARM_CTR_BTN_HEIGHT)
                                                    text:_isStartedAlarm ? @"停止" : @"開始"
                                                delegate:self action:@selector(alarmControlButtonTapEvent:)
                                                     tag:_isStartedAlarm ? ALARM_STOP : ALARM_START];
    
    //ボタンを保持しビューに追加
    if (tag == ALARM_START) {
        _startAlarmButton = alarmControlButton;
        [self.view addSubview:_startAlarmButton];
    } else if (tag == ALARM_STOP) {
        _stopAlarmButton = alarmControlButton;
        [self.view addSubview:_stopAlarmButton];
    }
}

//アラームコントロールボタンのタップイベント
- (void)alarmControlButtonTapEvent:(UIButton *)button
{
    NSUInteger tag = button.tag;
    
    if (tag == ALARM_START) {
        //現在時刻と設定時刻が同じならアラートを表示し処理しない
        if ([self isCurrentTime]) {
            [DCUtil showAlert:nil message:ALARM_ERROR_MESSAGE
            cancelButtonTitle:nil otherButtonTitles:@"OK"];
            return;
        }
        
        //アラームタイマー開始
        [self startAlarmTimer];
    } else if (tag == ALARM_STOP) {
        //アラームタイマー停止
        [self clearAlarmTimer];
        
        //アラーム停止
        [self stopAlarm];
    }
    _isStartedAlarm = tag == ALARM_START;
    
    //アラームコントロールボタン再配置
    [self resetAlarmControlButton];
}

//アラームコントロールボタン削除
- (void)removeAlarmControlButton:(NSUInteger)tag
{
    if (tag == ALARM_START) {
        [_startAlarmButton removeFromSuperview];
    } else if (tag == ALARM_STOP) {
        [_stopAlarmButton removeFromSuperview];
    }
}

//アラームコントロールボタン再配置
- (void)resetAlarmControlButton
{
    [self removeAlarmControlButton:_isStartedAlarm ? ALARM_STOP : ALARM_START];
    [self setAlarmControlButton:_isStartedAlarm ? ALARM_STOP : ALARM_START];
}

#pragma mark alarm timer

//アラームタイマー開始
- (void)startAlarmTimer
{
    if (_isStartedAlarm) {
        return;
    }
    
    //スリープ禁止
    [APP_DELEGATE setIdleTimer:YES];
    
    //アラート表示
    [DCUtil showAlert:nil message:ALARM_START_MESSAGE
    cancelButtonTitle:nil otherButtonTitles:@"OK"];
    
    //タイマー停止
    [self clearAlarmTimer];
    
    //タイマー開始
    _alarmTimer = [NSTimer scheduledTimerWithTimeInterval:ALARM_TIMER_INTERVAL target:self
                                                 selector:@selector(alarmTimerEvent:) userInfo:nil
                                                  repeats:YES];
}

//アラームタイマーイベント
- (void)alarmTimerEvent:(NSTimer *)timer
{
    //現在時刻が設定時刻であればアラームを鳴らす
    if ([self isCurrentTime]) {
        if (_isStartedAlarm) {
            //タイマー停止
            [self clearAlarmTimer];
            
            //アラーム再生
            [self playAlarm];
        }
    }
}

//アラームタイマー停止
- (void)clearAlarmTimer
{
    if (!_isStartedAlarm) {
        return;
    }
    
    //スリープ許可
    [APP_DELEGATE setIdleTimer:NO];
    
    //タイマー停止
    if (_alarmTimer != NULL) {
        [_alarmTimer invalidate];
    }
}

#pragma mark play/stop alarm

//指定したアラームの再生
- (void)playAlarm
{
    [_alarmPlayer setNumberOfLoops:ALARM_PLAY_INFINITE];
    [_alarmPlayer play];
}

//指定したアラームの停止
- (void)stopAlarm
{
    if ([_alarmPlayer isPlaying]) [_alarmPlayer stop];
}

#pragma mark date picker

//起床時間の選択ピッカー配置
- (void)setWakeUpTimePicker
{
    //起床時間の選択ピッカーを入れるビュー追加
    UIView *wakeUpTimePickerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height- ALARM_PICKER_HEIGHT, ALARM_PICKER_WIDTH, ALARM_PICKER_HEIGHT)];
    [self.view addSubview:wakeUpTimePickerView];
    
    //起床時間の選択ピッカー初期化
    _alarmPicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, ALARM_PICKER_WIDTH, ALARM_PICKER_HEIGHT)];
    
    //日付の表示モードを変更する(時分を表示)
    _alarmPicker.datePickerMode = UIDatePickerModeTime;
    
    //何分刻みにするか
    _alarmPicker.minuteInterval = ALARM_PICKER_MINUTE_INTERVAL;
    
    //初期時刻設定
    [_alarmPicker setDate:[self wakeUpDate]];
    
    //起床時間の選択ピッカーの値が変更されたときに呼ばれるメソッドを設定
    [_alarmPicker addTarget:self
                     action:@selector(alarmPickerChanged:)
           forControlEvents:UIControlEventValueChanged];
    
    //UIDatePickerのインスタンスをビューに追加
    [wakeUpTimePickerView addSubview:_alarmPicker];
}

//起床時間の選択ピッカー変更時のイベント
- (void)alarmPickerChanged:(UIDatePicker *)datePicker
{
    //アラーム開始フラグを下ろす
    _isStartedAlarm = NO;
    
    //起床時間更新
    [self updateWakeUpTimeLabel:[self wakeUpTimeText]];
    
    //アラームが鳴っていたらアラーム停止
    [self stopAlarm];
    
    //タイマー停止
    [self clearAlarmTimer];
    
    //停止ボタンを開始ボタンへ変更
    [self resetAlarmControlButton];
}

#pragma mark getter method

//起床時間のテキスト取得
- (NSString *)wakeUpTimeText
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = ALARM_TIME_DATE_FORMAT;
    return [dateFormatter stringFromDate:_alarmPicker.date];
}

//起床時間取得
- (NSDate *)wakeUpDate
{
    NSString *wakeUpDateString = wakeUpTime;
    NSDateFormatter *dateFormater = [[NSDateFormatter alloc] init];
    [dateFormater setDateFormat:ALARM_TIME_DATE_FORMAT];
    NSDate *wakeUpDate = [dateFormater dateFromString:wakeUpDateString];
    return wakeUpDate;
}

//UIDatePickerで指定されている時刻(時)取得
- (NSInteger)wakeUpDatePickerHour
{
    NSDateFormatter *hourFormatter = [[NSDateFormatter alloc] init];
    [hourFormatter setLocale:[NSLocale currentLocale]];
    [hourFormatter setDateFormat:@"HH"];
    NSString *datePickerHour = [hourFormatter stringFromDate:_alarmPicker.date];
    return [datePickerHour intValue];
}

//UIDatePickerで指定されている時刻(分)取得
- (NSInteger)wakeUpDatePickerMinute
{
    NSDateFormatter *minuteFormatter = [[NSDateFormatter alloc] init];
    [minuteFormatter setLocale:[NSLocale currentLocale]];
    [minuteFormatter setDateFormat:@"mm"];
    NSString *datePickerMinute = [minuteFormatter stringFromDate:_alarmPicker.date];
    return [datePickerMinute intValue];
}

//現在時刻であるか
- (BOOL)isCurrentTime
{
    return ([self currentHour] == [self wakeUpDatePickerHour] &&
            [self currentMinute] == [self wakeUpDatePickerMinute]);
}
//現在の日付を取得
- (NSInteger)currentDay
{
    NSDateComponents *currentTimeComponents = [self currentDateComponents];
    return currentTimeComponents.day;
}

//現在の時間を取得
- (NSInteger)currentHour
{
    NSDateComponents *currentTimeComponents = [self currentDateComponents];
    return currentTimeComponents.hour;
}

//現在の分数を取得
- (NSInteger)currentMinute
{
    NSDateComponents *currentTimeComponents = [self currentDateComponents];
    return currentTimeComponents.minute;
}

//現在時刻のコンポーネント取得
- (NSDateComponents *)currentDateComponents
{
    //現在の時刻を取得
    NSDate *nowDate = [NSDate date];
    
    //現在時刻のコンポーネント定義
    NSDateComponents *nowComponents;
    nowComponents = [[NSCalendar currentCalendar] components:(NSHourCalendarUnit |
                                                              NSMinuteCalendarUnit |
                                                              NSSecondCalendarUnit)
                                                    fromDate:nowDate];
    return nowComponents;
}

@end

//
//  ViewController.m
//  YR-Lan
//
//  Created by 杨荣 on 2019/6/18.
//  Copyright © 2019年 深圳市乐售云科技有限公司. All rights reserved.
//

#import "ViewController.h"
#import "YRLanServer.h"
#import "YRLanClient.h"
#import "LSIPAdress.h"
#import "IQKeyboardManager.h"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,strong) UITableView *serverLogTableView;
@property (nonatomic,strong) UITableView *clientLogTableView;

@property (nonatomic,strong) NSMutableArray *serverLogArray;
@property (nonatomic,strong) NSMutableArray *clientLogArray;

@property (nonatomic,strong) UITextField *serverIpTextField;
@property (nonatomic,strong) UITextField *serverPortTextField;
@property (nonatomic,strong) UITextField *clientIpTextField;
@property (nonatomic,strong) UITextField *clientPortTextField;
@property (nonatomic,strong) UITextField *clientSendDataTextField;


@property (nonatomic,strong) YRLanServer *server;
@property (nonatomic,strong) YRLanClient *client;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    IQKeyboardManager *manager = [IQKeyboardManager sharedManager];
    manager.enable = YES;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboardAction)];
    [self.view addGestureRecognizer:tap];
    self.view.userInteractionEnabled = YES;
    
    [self setupServerUI];
    [self setupClientUI];
    
    
}

- (YRLanClient *)client {
    if (!_client) {
        _client = [[YRLanClient alloc] init];
    }
    return _client;
}
- (YRLanServer *)server {
    if (!_server) {
        _server = [YRLanServer sharedInstance];
    }
    return _server;
}

- (void)serverOpen {
    NSInteger port = [self.serverPortTextField.text integerValue];
    [self.server openMonitorWithPort:port monitorDidUpdated:^(NSArray<GCDAsyncSocket *> * _Nonnull connectedSockets, GCDAsyncSocket * _Nonnull currentSocket, BOOL isNewConnected) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *log = [NSString stringWithFormat:@"当前已连接的客户端个数为：%zd",connectedSockets.count];
            [self.serverLogArray addObject:log];
            [self.serverLogTableView reloadData];
            [self.serverLogTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.serverLogArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        });
        
    } failure:^(NSString * _Nonnull errorMessage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *log = [NSString stringWithFormat:@"%@",errorMessage];
            [self.serverLogArray addObject:log];
            [self.serverLogTableView reloadData];
            [self.serverLogTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.serverLogArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        });
    }];
    
    
    // 接收到客户端数据
    [self.server didReceivedData:^(GCDAsyncSocket * _Nonnull clientSocket, NSData * _Nonnull data, NSString * _Nonnull dataString) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *log = [NSString stringWithFormat:@"【接收到数据】%@",dataString];
            [self.serverLogArray addObject:log];
            [self.serverLogTableView reloadData];
            [self.serverLogTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.serverLogArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            
            // 向客户端应答一下
            NSString *data = [NSString stringWithFormat:@"我是服务端%@",[LSIPAdress getIPAdress]];
            [self.server sendData:data clientSocket:clientSocket progress:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *log = [NSString stringWithFormat:@"正在发送数据"];
                    [self.serverLogArray addObject:log];
                    [self.serverLogTableView reloadData];
                    [self.serverLogTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.serverLogArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                });
            } success:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *log = [NSString stringWithFormat:@"数据发送成功"];
                    [self.serverLogArray addObject:log];
                    [self.serverLogTableView reloadData];
                    [self.serverLogTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.serverLogArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                });
            } failure:^(NSString * _Nonnull errorMessage) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *log = [NSString stringWithFormat:@"%@",errorMessage];
                    [self.serverLogArray addObject:log];
                    [self.serverLogTableView reloadData];
                    [self.serverLogTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.serverLogArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                });
            }];
            
            
        });
    }];
    
}
- (void)serverClose {
    NSString *log = [NSString stringWithFormat:@"关闭监听"];
    [self.serverLogArray addObject:log];
    [self.serverLogTableView reloadData];
    [self.serverLogTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.serverLogArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    
    [self.server closeMonitor];
}
- (void)clearServerLog {
    [self.serverLogArray removeAllObjects];
    [self.serverLogTableView reloadData];
}

- (void)clientConnect {
    
    NSString *ip = self.clientIpTextField.text;
    NSInteger port = [self.clientPortTextField.text integerValue];
    
    
    [self.client connectToHost:ip onPort:port progress:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *log = [NSString stringWithFormat:@"正在连接"];
            [self.clientLogArray addObject:log];
            [self.clientLogTableView reloadData];
            [self.clientLogTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.clientLogArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        });
    } success:^(NSString * _Nonnull successMessage) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *log = [NSString stringWithFormat:@"连接成功"];
            [self.clientLogArray addObject:log];
            [self.clientLogTableView reloadData];
            [self.clientLogTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.clientLogArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        });
        
    } failure:^(NSString * _Nonnull errorMessage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *log = [NSString stringWithFormat:@"%@",errorMessage];
            [self.clientLogArray addObject:log];
            [self.clientLogTableView reloadData];
            [self.clientLogTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.clientLogArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        });
    }];
    
    // 接收到服务端数据
    [self.client didReceivedData:^(NSData * _Nonnull data, NSString * _Nonnull dataString) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *log = [NSString stringWithFormat:@"【接收到数据】%@",dataString];
            [self.clientLogArray addObject:log];
            [self.clientLogTableView reloadData];
            [self.clientLogTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.clientLogArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        });
    }];
}
- (void)clientDisConnect {
    [self.client disConnect];
}
- (void)clientSendData {
    NSString *data = self.clientSendDataTextField.text;
    [self.client sendData:data progress:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *log = [NSString stringWithFormat:@"正在发送数据"];
            [self.clientLogArray addObject:log];
            [self.clientLogTableView reloadData];
            [self.clientLogTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.clientLogArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        });
    } success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *log = [NSString stringWithFormat:@"数据发送成功"];
            [self.clientLogArray addObject:log];
            [self.clientLogTableView reloadData];
            [self.clientLogTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.clientLogArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        });
    } failure:^(NSString * _Nonnull errorMessage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *log = [NSString stringWithFormat:@"%@",errorMessage];
            [self.clientLogArray addObject:log];
            [self.clientLogTableView reloadData];
            [self.clientLogTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.clientLogArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        });
    }];
}
- (void)clearClientLog {
    [self.clientLogArray removeAllObjects];
    [self.clientLogTableView reloadData];
}



- (NSMutableArray *)serverLogArray {
    if (!_serverLogArray) {
        _serverLogArray = [NSMutableArray array];
    }
    return _serverLogArray;
}
- (NSMutableArray *)clientLogArray {
    if (!_clientLogArray) {
        _clientLogArray = [NSMutableArray array];
    }
    return _clientLogArray;
}


- (void)setupServerUI {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height*0.5);
    [self.view addSubview:view];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.frame = CGRectMake(10, 20, 100, 44);
    titleLabel.text = @"服务端";
    titleLabel.font = [UIFont boldSystemFontOfSize:25];
    [view addSubview:titleLabel];
    
    NSArray *titleArray = @[@"ip:",@"port:"];
    NSArray *placeholderArray = @[@"ip地址",@"端口号"];
    NSArray *valueArray = @[[LSIPAdress getIPAdress],@"9100"];
    NSArray *buttonArray = @[@"开启",@"关闭"];
    for (NSInteger i = 0; i < 2; i++) {
        UILabel *label = [[UILabel alloc] init];
        label.frame = CGRectMake(20, titleLabel.frame.origin.y+titleLabel.frame.size.height+20+54*i, 70, 44);
        label.text = titleArray[i];
        [view addSubview:label];
        
        UIView *textFieldView = [[UIView alloc] init];
        textFieldView.backgroundColor = [UIColor whiteColor];
        textFieldView.frame = CGRectMake(label.frame.origin.x+label.frame.size.width, label.frame.origin.y, 150, label.frame.size.height);
        textFieldView.clipsToBounds = YES;
        textFieldView.layer.cornerRadius = 5;
        textFieldView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        textFieldView.layer.borderWidth = 0.5;
        [view addSubview:textFieldView];
        
        UITextField *textField = [[UITextField alloc] init];
        textField.frame = CGRectMake(10, 0, textFieldView.frame.size.width-20, textFieldView.frame.size.height);
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.placeholder = placeholderArray[i];
        textField.text = valueArray[i];
        if (i == 0) {
            textField.userInteractionEnabled = NO;
            textFieldView.layer.borderColor = [UIColor clearColor].CGColor;
            textFieldView.backgroundColor = [UIColor clearColor];
            self.serverIpTextField = textField;
            textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        }else {
            textField.userInteractionEnabled = YES;
            self.serverPortTextField = textField;
            textField.keyboardType = UIKeyboardTypeNumberPad;
        }
        [textFieldView addSubview:textField];
        
        UIButton *button = [UIButton buttonWithType:(UIButtonTypeSystem)];
        button.frame = CGRectMake(textFieldView.frame.origin.x+textFieldView.frame.size.width+10, textFieldView.frame.origin.y, 80, textFieldView.frame.size.height);
        [button setTitle:buttonArray[i] forState:(UIControlStateNormal)];
        [button setTitleColor:[UIColor whiteColor] forState:(UIControlStateNormal)];
        button.clipsToBounds = YES;
        button.layer.cornerRadius = 5;
        if (i == 0) {
            button.backgroundColor = [UIColor blueColor];
            [button addTarget:self action:@selector(serverOpen) forControlEvents:(UIControlEventTouchUpInside)];
        }else {
            button.backgroundColor = [UIColor redColor];
            [button addTarget:self action:@selector(serverClose) forControlEvents:(UIControlEventTouchUpInside)];
        }
        [view addSubview:button];
        
    }
    
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(20, titleLabel.frame.origin.y+titleLabel.frame.size.height+20+54*2, 70, 44);
    label.text = @"【日志】";
    [view addSubview:label];
    
    UIButton *clearButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
    clearButton.frame = CGRectMake(label.frame.origin.x+label.frame.size.width, label.frame.origin.y, 80, 44);
    [clearButton setTitle:@"清空日志" forState:(UIControlStateNormal)];
    clearButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [clearButton addTarget:self action:@selector(clearServerLog) forControlEvents:(UIControlEventTouchUpInside)];
    [view addSubview:clearButton];
    
    CGFloat originY = label.frame.origin.y+label.frame.size.height;
    UITableView *tableView = [[UITableView alloc] initWithFrame:(CGRectMake(20, originY, view.frame.size.width-40, view.frame.size.height-originY-10)) style:(UITableViewStylePlain)];
    tableView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    tableView.layer.borderWidth = 0.5;
    tableView.rowHeight = 30;
    tableView.dataSource = self;
    tableView.delegate = self;
    [view addSubview:tableView];
    self.serverLogTableView = tableView;
    
    
}

- (void)setupClientUI {
    
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor whiteColor];
    view.frame = CGRectMake(0, self.view.frame.size.height*0.5, self.view.frame.size.width, self.view.frame.size.height*0.5);
    [self.view addSubview:view];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.frame = CGRectMake(10, 20, 100, 44);
    titleLabel.text = @"客户端";
    titleLabel.font = [UIFont boldSystemFontOfSize:25];
    [view addSubview:titleLabel];
    
    NSArray *titleArray = @[@"ip:",@"port:",@"数据:"];
    NSArray *placeholderArray = @[@"ip地址",@"端口号",@"发送数据"];
    NSArray *valueArray = @[[LSIPAdress getIPAdress],@"9100",[NSString stringWithFormat:@"我是客户端%@",[LSIPAdress getIPAdress]]];
    NSArray *buttonArray = @[@"连接",@"断开",@"发送"];
    for (NSInteger i = 0; i < titleArray.count; i++) {
        UILabel *label = [[UILabel alloc] init];
        label.frame = CGRectMake(20, titleLabel.frame.origin.y+titleLabel.frame.size.height+20+54*i, 70, 44);
        label.text = titleArray[i];
        [view addSubview:label];
        
        UIView *textFieldView = [[UIView alloc] init];
        textFieldView.backgroundColor = [UIColor whiteColor];
        textFieldView.frame = CGRectMake(label.frame.origin.x+label.frame.size.width, label.frame.origin.y, 150, label.frame.size.height);
        textFieldView.clipsToBounds = YES;
        textFieldView.layer.cornerRadius = 5;
        textFieldView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        textFieldView.layer.borderWidth = 0.5;
        [view addSubview:textFieldView];
        
        UITextField *textField = [[UITextField alloc] init];
        textField.frame = CGRectMake(10, 0, textFieldView.frame.size.width-20, textFieldView.frame.size.height);
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.placeholder = placeholderArray[i];
        textField.text = valueArray[i];
        if (i == 0) {
            self.clientIpTextField = textField;
            textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        }else if (i == 1) {
            self.clientPortTextField = textField;
            textField.keyboardType = UIKeyboardTypeNumberPad;
        }else if (i == 2) {
            self.clientSendDataTextField = textField;
            textField.font = [UIFont systemFontOfSize:11];
        }
        [textFieldView addSubview:textField];
        
        UIButton *button = [UIButton buttonWithType:(UIButtonTypeSystem)];
        button.frame = CGRectMake(textFieldView.frame.origin.x+textFieldView.frame.size.width+10, textFieldView.frame.origin.y,  80, textFieldView.frame.size.height);
        [button setTitle:buttonArray[i] forState:(UIControlStateNormal)];
        [button setTitleColor:[UIColor whiteColor] forState:(UIControlStateNormal)];
        button.clipsToBounds = YES;
        button.layer.cornerRadius = 5;
        if (i == 0) {
            button.backgroundColor = [UIColor blueColor];
            [button addTarget:self action:@selector(clientConnect) forControlEvents:(UIControlEventTouchUpInside)];
        }else if (i == 1) {
            button.backgroundColor = [UIColor redColor];
            [button addTarget:self action:@selector(clientDisConnect) forControlEvents:(UIControlEventTouchUpInside)];
        }else if (i == 2) {
            button.backgroundColor = [UIColor greenColor];
            [button addTarget:self action:@selector(clientSendData) forControlEvents:(UIControlEventTouchUpInside)];
        }
        [view addSubview:button];
        
    }
    
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(20, titleLabel.frame.origin.y+titleLabel.frame.size.height+20+54*titleArray.count, 70, 44);
    label.text = @"【日志】";
    [view addSubview:label];
    
    UIButton *clearButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
    clearButton.frame = CGRectMake(label.frame.origin.x+label.frame.size.width, label.frame.origin.y, 80, 44);
    [clearButton setTitle:@"清空日志" forState:(UIControlStateNormal)];
    clearButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [clearButton addTarget:self action:@selector(clearClientLog) forControlEvents:(UIControlEventTouchUpInside)];
    [view addSubview:clearButton];
    
    
    CGFloat originY = label.frame.origin.y+label.frame.size.height;
    UITableView *tableView = [[UITableView alloc] initWithFrame:(CGRectMake(20, originY, view.frame.size.width-40, view.frame.size.height-originY-10)) style:(UITableViewStylePlain)];
    tableView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    tableView.layer.borderWidth = 0.5;
    tableView.rowHeight = 30;
    tableView.dataSource = self;
    tableView.delegate = self;
    [view addSubview:tableView];
    self.clientLogTableView = tableView;
    
}

#pragma mark 点击空白地方，隐藏键盘
- (void)hideKeyboardAction {
    [self.view endEditing:YES];
}

#pragma mark UITableViewDataSource,UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.serverLogTableView) {
        return self.serverLogArray.count;
    }else if (tableView == self.clientLogTableView) {
        return  self.clientLogArray.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleDefault) reuseIdentifier:@"cell"];
    }
    cell.textLabel.font = [UIFont systemFontOfSize:11];
    cell.textLabel.textColor = [UIColor blackColor];
    if (tableView == self.serverLogTableView) {
        cell.textLabel.text = [NSString stringWithFormat:@"↓%@",self.serverLogArray[indexPath.row]];
        if (indexPath.row == self.serverLogArray.count-1) {
            cell.textLabel.textColor = [UIColor redColor];
        }
    }else if (tableView == self.clientLogTableView) {
        cell.textLabel.text = [NSString stringWithFormat:@"↓%@",self.clientLogArray[indexPath.row]];
        if (indexPath.row == self.clientLogArray.count-1) {
            cell.textLabel.textColor = [UIColor redColor];
        }
    }
    
    
    return cell;
}
@end

//
//  YRLanServer.h
//  YR-Lan
//
//  Created by 杨荣 on 2019/6/18.
//  Copyright © 2019年 深圳市乐售云科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

NS_ASSUME_NONNULL_BEGIN


/**
 局域网通讯-服务端
 */
@interface YRLanServer : NSObject

+ (instancetype)sharedInstance;// 初始化

/* 监听 */
typedef void(^ServerMonitorDidUpdated)(NSArray <GCDAsyncSocket *>*connectedSockets,GCDAsyncSocket *currentSocket,BOOL isNewConnected);
typedef void(^ServerMonitorFailure)(NSString *errorMessage);
@property (nonatomic,copy) ServerMonitorDidUpdated serverMonitorDidUpdated;
@property (nonatomic,copy) ServerMonitorFailure serverMonitorFailure;
/* 发送数据 */
typedef void(^ServerSendDataProgress)(void);
typedef void(^ServerSendDataSuccess)(void);
typedef void(^ServerSendDataFailure)(NSString *errorMessage);
@property (nonatomic,copy) ServerSendDataProgress serverSendDataProgress;
@property (nonatomic,copy) ServerSendDataSuccess serverSendDataSuccess;
@property (nonatomic,copy) ServerSendDataFailure serverSendDataFailure;
/* 接收数据 */
typedef void(^ServerDidReceivedData)(GCDAsyncSocket *clientSocket, NSData *data, NSString *dataString);
@property (nonatomic,copy) ServerDidReceivedData serverDidReceivedData;



/********** 开启/关闭监听 **********/
- (void)openMonitorWithPort:(NSInteger)port
          monitorDidUpdated:(ServerMonitorDidUpdated)didUpdated
                    failure:(ServerMonitorFailure)failure;
- (void)closeMonitor;
/********** 发送/接收数据 **********/
- (void)sendData:(id)data
    clientSocket:(GCDAsyncSocket *)clientSocket
        progress:(ServerSendDataProgress)progress
         success:(ServerSendDataSuccess)success
         failure:(ServerSendDataFailure)failure;
- (void)didReceivedData:(ServerDidReceivedData)didReceivedData;


@end

NS_ASSUME_NONNULL_END

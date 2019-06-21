//
//  YRLanClient.h
//  YR-Lan
//
//  Created by 杨荣 on 2019/6/18.
//  Copyright © 2019年 深圳市乐售云科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

NS_ASSUME_NONNULL_BEGIN

/**
 局域网通讯-客户端
 */
@interface YRLanClient : NSObject

/* 连接 */
typedef void(^ClientConnectServerProgress)(void);
typedef void(^ClientConnectServerSuccess)(NSString *successMessage);
typedef void(^ClientConnectServerFailure)(NSString *errorMessage);
@property (nonatomic, copy) ClientConnectServerProgress clientConnectServerProgress;
@property (nonatomic, copy) ClientConnectServerSuccess clientConnectServerSuccess;
@property (nonatomic, copy) ClientConnectServerFailure clientConnectServerFailure;
/* 发送数据 */
typedef void(^ClientSendDataProgress)(void);
typedef void(^ClientSendDataSuccess)(void);
typedef void(^ClientSendDataFailure)(NSString *errorMessage);
@property (nonatomic,copy) ClientSendDataProgress clientSendDataProgress;
@property (nonatomic,copy) ClientSendDataSuccess clientSendDataSuccess;
@property (nonatomic,copy) ClientSendDataFailure clientSendDataFailure;
/* 接收数据 */
typedef void(^ClientDidReceivedData)(NSData *data, NSString *dataString);
@property (nonatomic,copy) ClientDidReceivedData clientDidReceivedData;



/********** 连接/断开 **********/
- (void)connectToHost:(NSString *)serverIp
               onPort:(NSInteger)port
             progress:(ClientConnectServerProgress)progress
              success:(ClientConnectServerSuccess)success
              failure:(ClientConnectServerFailure)failure;
- (void)disConnect;
/********** 发送/接收数据 **********/
- (void)sendData:(id)data
        progress:(ClientSendDataProgress)progress
         success:(ClientSendDataSuccess)success
         failure:(ClientSendDataFailure)failure;
- (void)didReceivedData:(ClientDidReceivedData)didReceivedData;


@end

NS_ASSUME_NONNULL_END

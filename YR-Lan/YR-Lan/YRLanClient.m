//
//  YRLanClient.m
//  YR-Lan
//
//  Created by 杨荣 on 2019/6/18.
//  Copyright © 2019年 深圳市乐售云科技有限公司. All rights reserved.
//

#import "YRLanClient.h"

@interface YRLanClient ()<GCDAsyncSocketDelegate>

@property(nonatomic,strong) GCDAsyncSocket *clientSocket;

@end

@implementation YRLanClient

- (GCDAsyncSocket *)clientSocket{
    if (!_clientSocket) {
        _clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        
    }
    return _clientSocket;
}

- (void)connectToHost:(NSString *)serverIp
               onPort:(NSInteger)port
             progress:(ClientConnectServerProgress)progress
              success:(ClientConnectServerSuccess)success
              failure:(ClientConnectServerFailure)failure {

    self.clientConnectServerProgress = progress;
    self.clientConnectServerSuccess = success;
    self.clientConnectServerFailure = failure;

    if (serverIp.length <= 0) {
        if (self.clientConnectServerFailure) {
            self.clientConnectServerFailure(@"连接失败：ip为空");
        }
        return;
    }

    if (port == 0  || port == NSNotFound) {
        if (self.clientConnectServerFailure) {
            self.clientConnectServerFailure(@"连接失败：端口为空");
        }
        return;
    }
    
    if (self.clientConnectServerProgress) {
        self.clientConnectServerProgress();
    }
    [self.clientSocket disconnect];
    
    NSLog(@"【Client】开始连接：ip = %@，port = %zd",serverIp,port);
    NSError *error = nil;
    BOOL result = [self.clientSocket connectToHost:serverIp onPort:port withTimeout:10 error:&error];
    if (result == NO || error) {
        NSString *string = [NSString stringWithFormat:@"连接失败：%@",error.localizedDescription];
        if (self.clientConnectServerFailure) {
            self.clientConnectServerFailure(string);
        }
    }
    
    
}
- (void)disConnect {
    [self.clientSocket disconnect];
}


- (void)sendData:(id)data
        progress:(ClientSendDataProgress)progress
         success:(ClientSendDataSuccess)success
         failure:(ClientSendDataFailure)failure {
    
    self.clientSendDataProgress = progress;
    self.clientSendDataSuccess = success;
    self.clientSendDataFailure = failure;
    
    if (!data) {
        if (self.clientSendDataFailure) {
            self.clientSendDataFailure(@"发送数据为空");
        }
        return;
    }
    if (!self.clientSocket.isConnected) {
        if (self.clientSendDataFailure) {
            self.clientSendDataFailure(@"未连接服务端");
        }
        return;
    }
    
    if (self.clientSendDataProgress) {
        self.clientSendDataProgress();
    }
    
    NSData *sendData = nil;
    if ([data isKindOfClass:[NSData class]]) {
        sendData = data;
    }else if ([data isKindOfClass:[NSDictionary class]] || [data isKindOfClass:[NSArray class]]) {
        sendData = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
    }else if ([data isKindOfClass:[NSString class]]) {
        sendData = [data dataUsingEncoding:NSUTF8StringEncoding];
    }else {
        if (self.clientSendDataFailure) {
            self.clientSendDataFailure(@"发送数据格式有误");
        }
        return;
    }
    
    [self.clientSocket writeData:sendData withTimeout:-1 tag:0];
}
- (void)didReceivedData:(ClientDidReceivedData)didReceivedData {
    self.clientDidReceivedData = didReceivedData;
}


#pragma mark <GCDAsyncSocketDelegate>
#pragma mark  GCDAsyncSocketDelegate 连接成功
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    NSLog(@"【Client】GCDAsyncSocketDelegate 连接成功");
    [self readDataWithServerSocket:sock clientSocket:self.clientSocket];
    if (self.clientConnectServerSuccess) {
        self.clientConnectServerSuccess(@"连接成功");
    }
}

#pragma mark GCDAsyncSocketDelegate 连接失败或失去连接
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    NSLog(@"【Client】GCDAsyncSocketDelegate 连接失败或失去连接：%@",err);
    if (self.clientConnectServerFailure) {
        
        if (err) {
            self.clientConnectServerFailure([NSString stringWithFormat:@"连接失败或失去连接：%@",err.localizedDescription]);
        }else {
            self.clientConnectServerFailure([NSString stringWithFormat:@"连接失败或失去连接：已断开连接"]);
        }
    }
    
}

#pragma mark GCDAsyncSocketDelegate 数据发送完毕
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    NSLog(@"【Client】GCDAsyncSocketDelegate 数据发送完毕");
    [self readDataWithServerSocket:sock clientSocket:self.clientSocket];
    if (self.clientSendDataSuccess) {
        self.clientSendDataSuccess();
    }
}

#pragma mark GCDAsyncSocketDelegate 已经接收到数据
- (void)socket:(GCDAsyncSocket *)sock didReadData:(nonnull NSData *)data withTag:(long)tag{
    NSLog(@"【Client】GCDAsyncSocketDelegate 已经接收到数据");
    NSString *didReceivedString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"【Client】GCDAsyncSocketDelegate 已经接收到数据：%@",didReceivedString);
    [self readDataWithServerSocket:sock clientSocket:self.clientSocket];
    if (self.clientDidReceivedData) {
        self.clientDidReceivedData(data, didReceivedString);
    }
}

#pragma mark - 继续打通使服务端和客户端的数据传输
- (void)readDataWithServerSocket:(GCDAsyncSocket *)serverSocket clientSocket:(GCDAsyncSocket *)clientSocket {
    [serverSocket readDataWithTimeout:-1 tag:0];
    [clientSocket readDataWithTimeout:-1 tag:0];
}

@end

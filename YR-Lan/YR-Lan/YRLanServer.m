//
//  YRLanServer.m
//  YR-Lan
//
//  Created by 杨荣 on 2019/6/18.
//  Copyright © 2019年 深圳市乐售云科技有限公司. All rights reserved.
//

#import "YRLanServer.h"

@interface YRLanServer ()<GCDAsyncSocketDelegate>

@property (nonatomic,strong) GCDAsyncSocket *serverSocket;
@property (nonatomic,strong) NSMutableArray <GCDAsyncSocket *>*connectedSockets;// 已经连接的客户端对象集合

@end

@implementation YRLanServer

static  YRLanServer *instance = nil;
+ (instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super alloc] init];
    });
    return instance;
}

- (GCDAsyncSocket *)serverSocket{
    if (!_serverSocket) {
        _serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    }
    return _serverSocket;
}

#pragma mark 已经连接的客户端对象集合
- (NSMutableArray<GCDAsyncSocket *> *)connectedSockets{
    if (!_connectedSockets) {
        _connectedSockets = [NSMutableArray array];
    }
    return _connectedSockets;
}


- (void)openMonitorWithPort:(NSInteger)port
          monitorDidUpdated:(ServerMonitorDidUpdated)didUpdated
                    failure:(ServerMonitorFailure)failure {
    NSLog(@"开始监听ip = %zd",port);
    self.serverMonitorDidUpdated = didUpdated;
    self.serverMonitorFailure = failure;
    
    if (port == 0  || port == NSNotFound) {
        if (self.serverMonitorFailure) {
            self.serverMonitorFailure(@"监听开启失败：端口不存在");
        }
    }
    [self closeMonitor];
    NSError *error = nil;
    BOOL result = [self.serverSocket acceptOnPort:port error:&error];
    if (result == NO || error) {// 当端口号被占用的时候会失败
        NSString *string = [NSString stringWithFormat:@"监听开启失败：%@",error.localizedDescription];
        NSLog(@"【Server】%@",string);
        if (self.serverMonitorFailure) {
            self.serverMonitorFailure(string);
        }
    }else {
        if (self.serverMonitorDidUpdated) {
            self.serverMonitorDidUpdated(nil, nil, NO);
        }
    }
}
- (void)closeMonitor {
    [self.serverSocket disconnect];
    [self.connectedSockets removeAllObjects];
}
- (void)sendData:(id)data
    clientSocket:(GCDAsyncSocket *)clientSocket
        progress:(ServerSendDataProgress)progress
         success:(ServerSendDataSuccess)success
         failure:(ServerSendDataFailure)failure {
    
    self.serverSendDataProgress = progress;
    self.serverSendDataSuccess = success;
    self.serverSendDataFailure = failure;
    
    if (!data) {
        if (self.serverSendDataFailure) {
            self.serverSendDataFailure(@"发送数据为空");
        }
        return;
    }
    if (!clientSocket) {
        if (self.serverSendDataFailure) {
            self.serverSendDataFailure(@"客户端不存在");
        }
        return;
    }
    if (!clientSocket.isConnected) {
        if (self.serverSendDataFailure) {
            self.serverSendDataFailure(@"该客户端未连接");
        }
        return;
    }
    
    if (self.serverSendDataProgress) {
        self.serverSendDataProgress();
    }
    
    NSData *sendData = nil;
    if ([data isKindOfClass:[NSData class]]) {
        sendData = data;
    }else if ([data isKindOfClass:[NSDictionary class]] || [data isKindOfClass:[NSArray class]]) {
        sendData = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
    }else if ([data isKindOfClass:[NSString class]]) {
        sendData = [data dataUsingEncoding:NSUTF8StringEncoding];
    }else {
        if (self.serverSendDataFailure) {
            self.serverSendDataFailure(@"发送数据格式有误");
        }
        return;
    }
    
    [clientSocket writeData:sendData withTimeout:-1 tag:0];
}
- (void)didReceivedData:(ServerDidReceivedData)didReceivedData {
    self.serverDidReceivedData = didReceivedData;
}

#pragma mark <GCDAsyncSocketDelegate>
#pragma mark GCDAsyncSocketDelegate 已经监听到有新的客户端连接
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
    NSLog(@"【Server】GCDAsyncSocketDelegate 已经监听到有新的客户端连接");
    [self readDataWithServerSocket:self.serverSocket clientSocket:newSocket];
    [self.connectedSockets addObject:newSocket];// 必须要保存已经连接的客户端对象，不保存服务端会立即断开
    if (self.serverMonitorDidUpdated) {
        self.serverMonitorDidUpdated(self.connectedSockets,newSocket,YES);
    }
}

#pragma mark GCDAsyncSocketDelegate 已经失去某个客户端连接
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    NSLog(@"【Server】GCDAsyncSocketDelegate 已经失去某个客户端连接");
    [self.connectedSockets removeObject:sock];
    if (self.serverMonitorDidUpdated) {
        self.serverMonitorDidUpdated(self.connectedSockets,sock,NO);
    }
}

#pragma mark GCDAsyncSocketDelegate 数据发送完毕
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    NSLog(@"【Server】GCDAsyncSocketDelegate 数据发送完毕");
    [self readDataWithServerSocket:self.serverSocket clientSocket:sock];
    if (self.serverSendDataSuccess) {
        self.serverSendDataSuccess();
    }
}

#pragma mark GCDAsyncSocketDelegate 已经接收到数据
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSLog(@"【Server】GCDAsyncSocketDelegate 已经接收到数据");
    NSString *didReceivedString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"【Server】GCDAsyncSocketDelegate 已经接收到数据：%@",didReceivedString);
    @synchronized(self) {
        [self readDataWithServerSocket:self.serverSocket clientSocket:sock];
        if (self.serverDidReceivedData) {
            self.serverDidReceivedData(sock, data, didReceivedString);
        }
    }
}

#pragma mark - 继续打通使服务端和客户端的数据传输
- (void)readDataWithServerSocket:(GCDAsyncSocket *)serverSocket clientSocket:(GCDAsyncSocket *)clientSocket {
    [serverSocket readDataWithTimeout:-1 tag:0];
    [clientSocket readDataWithTimeout:-1 tag:0];
}

@end

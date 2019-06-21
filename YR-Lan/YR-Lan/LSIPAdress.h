//
//  LSIPAdress.h
//  LSLanServer
//
//  Created by 杨荣 on 2018/6/14.
//  Copyright © 2018年 Imac. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 ip地址获取（包含WiFi下的ip地址和运营商下的ip地址）
 */
@interface LSIPAdress : NSObject

+ (NSString *)getIPAdress;// ip地址获取（包含WiFi下的ip地址和运营商下的ip地址）

@end

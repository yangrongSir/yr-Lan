//
//  LSIPAdress.m
//  LSLanServer
//
//  Created by 杨荣 on 2018/6/14.
//  Copyright © 2018年 Imac. All rights reserved.
//

#import "LSIPAdress.h"

/* 导入头文件 -> 获取WiFi下的ip地址 */
#import <ifaddrs.h>
#import <arpa/inet.h>

/* 导入头文件 -> 获取运营商网络下(2G、3G、4G)的ip地址 */
#import  <sys/socket.h>
#import  <sys/sockio.h>
#import  <sys/ioctl.h>
#import  <net/if.h>
#import  <arpa/inet.h>

@implementation LSIPAdress

+ (NSString *)getIPAdress {
    
    NSString *getIPAdressWithWiFi = [self getIPAdressWithWiFi];// A类ip地址
    NSString *getIPAdressWithOperator = [self getIPAdressWithOperator];// C类ip地址
    
    NSLog(@"getIPAdressWithWiFi = %@ getIPAdressWithOperator = %@",getIPAdressWithWiFi,getIPAdressWithOperator);
    
    // 能获取A
    if (getIPAdressWithWiFi.length <= 0) {
        return getIPAdressWithOperator;
    }else {
        return getIPAdressWithWiFi;
    }
}

#pragma mark  ---------- 获取WiFi下的ip地址 ----------
+ (NSString *)getIPAdressWithWiFi {
    
    NSString *address = nil;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
    
}


#pragma mark  ---------- 获取运营商网络下(2G、3G、4G)的ip地址 ----------
+ (NSString *)getIPAdressWithOperator {
    int sockfd = socket(AF_INET,SOCK_DGRAM, 0);
    // if (sockfd <</span> 0) return nil; //这句报错，由于转载的，不太懂，注释掉无影响，懂的大神欢迎指导
    NSMutableArray *ips = [NSMutableArray array];
    
    int BUFFERSIZE =4096;
    
    struct ifconf ifc;
    
    char buffer[BUFFERSIZE], *ptr, lastname[IFNAMSIZ], *cptr;
    
    struct ifreq *ifr, ifrcopy;
    
    ifc.ifc_len = BUFFERSIZE;
    
    ifc.ifc_buf = buffer;
    
    if (ioctl(sockfd,SIOCGIFCONF, &ifc) >= 0){
        
        for (ptr = buffer; ptr < buffer + ifc.ifc_len; ){
            
            ifr = (struct ifreq *)ptr;
            
            int len =sizeof(struct sockaddr);
            
            if (ifr->ifr_addr.sa_len > len) {
                len = ifr->ifr_addr.sa_len;
            }
            
            ptr += sizeof(ifr->ifr_name) + len;
            
            if (ifr->ifr_addr.sa_family !=AF_INET) continue;
            
            if ((cptr = (char *)strchr(ifr->ifr_name,':')) != NULL) *cptr =0;
            
            if (strncmp(lastname, ifr->ifr_name,IFNAMSIZ) == 0)continue;
            
            memcpy(lastname, ifr->ifr_name,IFNAMSIZ);
            
            ifrcopy = *ifr;
            
            ioctl(sockfd,SIOCGIFFLAGS, &ifrcopy);
            
            if ((ifrcopy.ifr_flags &IFF_UP) == 0)continue;
            
            NSString *ip = [NSString stringWithFormat:@"%s",inet_ntoa(((struct sockaddr_in *)&ifr->ifr_addr)->sin_addr)];
            [ips addObject:ip];
        }
    }
    close(sockfd);
    
    NSString *deviceIP = @"";
    
    for (int i=0; i < ips.count; i++){
        if (ips.count >0){
            deviceIP = [NSString stringWithFormat:@"%@",ips.lastObject];
        }
    }
    
    return deviceIP;
}

@end

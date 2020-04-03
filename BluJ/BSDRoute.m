//
//  BSDRoute.m
//  BluJ
//
//  Created by Lavergne, Marc on 3/26/20.
//  Copyright © 2020 Lavergne, Marc. All rights reserved.
//


#import "BSDRoute.h"

#import <sys/socket.h>
#import <netinet/in.h>
#import <net/if_dl.h>
#import <sys/sysctl.h>
#import <net/route.h>
#import <arpa/inet.h>

//
// Code follows methodologies in the following:
// https://opensource.apple.com/source/bootp/bootp-89.2/IPConfiguration.bproj/ipconfigd.c
// It appears to be consistent with routing table socket operations in BSD
//

@interface BSDRoute() {
    struct sockaddr     m_addrs[RTAX_MAX];
    struct rt_msghdr2   m_rtm;
    int                 m_len;      /* length of the sockaddr array */
}
@end

@implementation BSDRoute

+ (NSMutableArray<BSDRoute*>*) getRoutes {
    NSMutableArray* routeArray = [NSMutableArray array];

    size_t len;
    int mib[6];
    char *buf, *next;
    register struct rt_msghdr2 *rtm;

    mib[0] = CTL_NET;
    mib[1] = PF_ROUTE;
    mib[2] = 0;
    mib[3] = 0;
    mib[4] = NET_RT_DUMP2;
    mib[5] = 0;

    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        NSLog(@"BSDRoute sysctl size estimate failed for NET_RT_DUMP2");
        return NULL;
    }
    if ((buf = malloc(len)) == 0) {
        NSLog(@"BSDRoute malloc failed %lu", (unsigned long)len);
        return NULL;
    }
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        NSLog(@"sysctl: sysctl buf read failed for NET_RT_DUMP2");
        return NULL;
    }

    for (next = buf; next <  buf + len; next += rtm->rtm_msglen) {
        rtm = (struct rt_msghdr2 *)next;
        BSDRoute* route =  route = [self bsdRoute:rtm];
        if (route != NULL) {
            [routeArray addObject:route];
        }
    }
    free(buf);

    return routeArray;
}

+ (BSDRoute*) bsdRoute:(struct rt_msghdr2 *)rtm {
    // sockaddrs are after the message header
    struct sockaddr* dst_sa = (struct sockaddr *)(rtm + 1);

    if (rtm->rtm_addrs & RTA_DST) {
        switch(dst_sa->sa_family) {
            case AF_INET:
                if (dst_sa->sa_family == AF_INET && !((rtm->rtm_flags & RTF_WASCLONED) && (rtm->rtm_parentflags & RTF_PRCLONING))) {
                    return [[BSDRoute alloc] initWithRtm:rtm];
                }
        }
    }

    return NULL;
}

-(void) setAddr:(struct sockaddr*)sa index:(int)rtax_index {
    if (rtax_index >= 0 && rtax_index < RTAX_MAX) {
        memcpy(&(m_addrs[rtax_index]), sa, sizeof(struct sockaddr));
    }
}

-(NSString*) getDetails {
    NSMutableString* result = [[NSMutableString alloc] init];
    [result appendFormat: @"message type: 0x%06x\n", m_rtm.rtm_type];
    [result appendFormat: @"flags: 0x%06x\n", m_rtm.rtm_flags];
    [result appendFormat: @"addrs: 0x%06x\n", m_rtm.rtm_addrs];

    return result;
}

-initWithRtm: (struct rt_msghdr2*) rtm {
    struct sockaddr* sa = (struct sockaddr*)(rtm + 1);

    //copy over the route message
    memcpy(&(m_rtm), rtm, sizeof(struct rt_msghdr2));
    for (int i = 0; i < RTAX_MAX; i++) {
        [self setAddr:&(sa[i]) index:i];
    }
    
    self.destination = [self getAddrStringByIndex:RTAX_DST];
    self.netmask = [self getAddrStringByIndex:RTAX_NETMASK];
    self.gateway = [self getAddrStringByIndex:RTAX_GATEWAY];

    return self;
}

-(NSString*) getAddrStringByIndex: (int)rtax_index {
    NSString * routeString = NULL;
    struct sockaddr* sa = &(m_addrs[rtax_index]);
    int flagVal = 1 << rtax_index;

    if (!(m_rtm.rtm_addrs & flagVal)) {
        return @"none";
    }


    if (rtax_index >= 0 && rtax_index < RTAX_MAX) {
        switch(sa->sa_family) {
            case AF_INET:
            {
                struct sockaddr_in* si = (struct sockaddr_in *)sa;
                if (si->sin_addr.s_addr == INADDR_ANY) {
                    routeString = @"default";
                } else {
                    routeString = [NSString stringWithCString:(char *)inet_ntoa(si->sin_addr) encoding:NSASCIIStringEncoding];
                }
            }
            break;

            case AF_LINK:
            {
                struct sockaddr_dl* sdl = (struct sockaddr_dl*)sa;
                if (sdl->sdl_nlen + sdl->sdl_alen + sdl->sdl_slen == 0) {
                    routeString = [NSString stringWithFormat: @"link #%d", sdl->sdl_index];
                } else {
                    routeString = [NSString stringWithCString:link_ntoa(sdl) encoding:NSASCIIStringEncoding];
                }
            }
            break;

            default:
            {
                char a[3 * sa->sa_len];
                char *cp;
                char *sep = "";
                int i;

                if (sa->sa_len == 0) {
                    routeString = @"empty";
                }
                else {
                    a[0] = (char)NULL;
                    for (i = 0, cp = a; i < sa->sa_len; i++) {
                        cp += sprintf(cp, "%s%02x", sep, (unsigned char)sa->sa_data[i]);
                        sep = ":";
                    }
                    routeString = [NSString stringWithCString:a encoding:NSASCIIStringEncoding];
                }
            }
        }
    }
    
    return routeString;
}

+ (struct in_addr) createAddr:(NSString *)ipString {
    struct in_addr inAddr;
    inet_pton(AF_INET, (char *)ipString.UTF8String, &inAddr);
    return inAddr;
}

+ (struct sockaddr_in) createSockAddr:(NSString *)ipString {
    struct sockaddr_in sockAddr;
    sockAddr.sin_len = sizeof(sockAddr);
    sockAddr.sin_family = AF_INET;
    sockAddr.sin_port = htons(80);
    sockAddr.sin_addr = [BSDRoute createAddr:ipString];
    return sockAddr;
}

+ (BOOL) addRoute:(NSString *)ipDestination ipGateway:(NSString *)ipGateway ifName:(NSString *)ifName {
    return [BSDRoute route:RTM_ADD ipDestination:ipDestination ipGateway:ipGateway ifName:ifName];
}

+ (BOOL) delRoute:(NSString *)ipDestination ipGateway:(NSString *)ipGateway ifName:(NSString *)ifName {
    return [BSDRoute route:RTM_DELETE ipDestination:ipDestination ipGateway:ipGateway ifName:ifName];
}

+ (BOOL) route:(u_char)cmd ipDestination:(NSString *)ipDestination ipGateway:(NSString *)ipGateway ifName:(NSString *)ifName {
    char *ifname = ifName != NULL ? (char *)ifName.UTF8String : NULL;
    
    struct in_addr netaddr = [BSDRoute createAddr:ipDestination];
    struct in_addr gateway = [BSDRoute createAddr:ipGateway];
    struct in_addr netmask = [BSDRoute createAddr:@"255.255.255.192"];

    int rtm_seq = 0;
    struct {
        struct rt_msghdr hdr;
        struct sockaddr_in dst;
        struct sockaddr_in gway;
        struct sockaddr_in mask;
        struct sockaddr_dl link;
    } rtmsg;

    int sockfd = sockfd = socket(PF_ROUTE, SOCK_RAW, AF_INET);
    if (sockfd < 0) {
        NSLog(@"subnet_route: open routing socket failed, %s", strerror(errno));
        return FALSE;
    }

    memset(&rtmsg, 0, sizeof(rtmsg));
    rtmsg.hdr.rtm_type = cmd;
    rtmsg.hdr.rtm_flags = RTF_UP | RTF_STATIC | RTF_CLONING;
    rtmsg.hdr.rtm_version = RTM_VERSION;
    rtmsg.hdr.rtm_seq = ++rtm_seq;
    rtmsg.hdr.rtm_addrs = RTA_DST | RTA_GATEWAY | RTA_NETMASK;
    
    rtmsg.dst.sin_len = sizeof(rtmsg.dst);
    rtmsg.dst.sin_family = AF_INET;
    rtmsg.dst.sin_addr = netaddr;
    
    rtmsg.gway.sin_len = sizeof(rtmsg.gway);
    rtmsg.gway.sin_family = AF_INET;
    rtmsg.gway.sin_addr = gateway;
    
    rtmsg.mask.sin_len = sizeof(rtmsg.mask);
    rtmsg.mask.sin_family = AF_INET;
    rtmsg.mask.sin_addr = netmask;

    int len = sizeof(rtmsg);
    if (ifname) {
        rtmsg.link.sdl_len = sizeof(rtmsg.link);
        rtmsg.link.sdl_family = AF_LINK;
        rtmsg.link.sdl_nlen = strlen(ifname);
        rtmsg.hdr.rtm_addrs |= RTA_IFP;
        bcopy(ifname, rtmsg.link.sdl_data, rtmsg.link.sdl_nlen);
    } else {
        /* no link information */
        len -= sizeof(rtmsg.link);
    }
    rtmsg.hdr.rtm_msglen = len;
    
    BOOL result = TRUE;
    if (write(sockfd, &rtmsg, len) < 0) {
        int    error = errno;

        switch (error) {
            case ESRCH:
            case EEXIST:
                NSLog(@"subnet_route: write routing socket failed, %s", strerror(error));
                result = FALSE;
                break;
            default:
                NSLog(@"subnet_route: write routing socket failed, %s", strerror(error));
                result = FALSE;
                break;
        }
    }
    
    if (sockfd >= 0) {
        close(sockfd);
    }
    
    return result;
}


@end

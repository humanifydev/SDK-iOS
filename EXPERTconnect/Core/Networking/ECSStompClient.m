//
//  ECSStompClient.m
//  EXPERTconnect
//
//  Copyright (c) 2015 Humanify, Inc. All rights reserved.
//

#import "ECSStompClient.h"

#import "ECSChatMessage.h"
#import "EXPERTconnect.h"
#import "ECSJSONSerializing.h"
#import "ECSJSONSerializer.h"
#import "ECSLog.h"
#import "ECSWebSocket.h"

static NSString * const kStompVersion =     @"1.2";

static NSString * const kStompConnect =     @"CONNECT";
static NSString * const kStompConnected =   @"CONNECTED";
static NSString * const kStompSend =        @"SEND";
static NSString * const kStompSubscribe =   @"SUBSCRIBE";
static NSString * const kStompUnsubscribe = @"UNSUBSCRIBE";
static NSString * const kStompAck =         @"ACK";
static NSString * const kStompNack =        @"NACK";
static NSString * const kStompBegin =       @"BEGIN";
static NSString * const kStompCommit =      @"COMMIT";
static NSString * const kStompAbort =       @"ABORT";
static NSString * const kStompDisconnect =  @"DISCONNECT";
static NSString * const kStompMessage =     @"MESSAGE";
static NSString * const kStompReceipt =     @"RECEIPT";
static NSString * const kStompError =       @"ERROR";

static NSString * const kStompReceiptID = @"ios-1-subscribe";


// Stomp Frame Object  ------------------------------------------------------------------------

@implementation ECSStompFrame

- (instancetype)init {
    
    self = [super init];
    
    if (self) {
        self.headers = [NSMutableDictionary new];
    }
    
    return self;
}

- (NSString *)description {
    
    return [NSString stringWithFormat:@"CMD: %@\nHeaders: %@\nBody: %@", self.command, self.headers, self.body];
}

@end


// Heart-beat Timer Object  -------------------------------------------------------------------

@interface HeartBeatTimerTarget : NSObject

@property (weak, nonatomic) id realTarget;

@end

@implementation HeartBeatTimerTarget

-(void)doStompHeartbeat:(NSTimer *)theTimer {
    
    [self.realTarget performSelector:@selector(doStompHeartbeat:) withObject:theTimer];
}

@end


// Humanify Stomp Client  ---------------------------------------------------------------------

@interface ECSStompClient() <ECSWebSocketDelegate>

@property (strong, nonatomic) ECSWebSocket          *webSocket;
//@property (strong, nonatomic) NSURL                 *hostURL;
@property (strong, nonatomic) NSMutableDictionary   *subscribers;

@end


@implementation ECSStompClient

int         _clientHeartbeatInterval;
int         _clientHeartbeatsMissed;
bool        _wasConnected;
//bool        _isConnecting;

@synthesize authToken;

- (instancetype)init {
    
    self = [super init];
    
    if (self) {
        
        self.subscribers = [NSMutableDictionary new];
        
        authToken = @"";
        
        _clientHeartbeatInterval = 0;
        _clientHeartbeatsMissed =  0;
        
        _wasConnected =  NO;
        _isConnecting =  NO;
        self.connected = NO;
        
        self.logger = [[EXPERTconnect shared] logger];
    }
    
    return self;
}

- (void)dealloc {
    
    [self unregisterForNotifications];
    
    [self.subscribers removeAllObjects];
}

- (NSString *)readyStateString {
    switch(self.webSocket.readyState) {
        case ECS_CONNECTING:    return @"0-CONNECTING";
        case ECS_OPEN:          return @"1-OPEN";
        case ECS_CLOSING:       return @"2-CLOSING";
        case ECS_CLOSED:        return @"3-CLOSED";
        default:                return @"UNKNOWN";
    }
}

- (BOOL) connectToHost:(NSString*)host {
    
    if( self.webSocket &&
       ( self.webSocket.readyState == ECS_OPEN || self.webSocket.readyState == ECS_CONNECTING ) ) {

        ECSLogError(self.logger, @"Connection in progress or already connected. Blocking additional attempt. Connected? %d. Connecting? %d. ReadyState=%@",
                    self.connected, _isConnecting, [self readyStateString]);
        return NO;
    }
    
    _isConnecting = YES;
    
    self.hostURL = [NSURL URLWithString:host];
    
    NSURL *url = self.hostURL;
    
    // Add the auth token to the URL string
    if(self.authToken) {
        
        NSString *queryString = [NSString stringWithFormat:@"access_token=%@", self.authToken];
        
        NSString *URLString = [[NSString alloc] initWithFormat:@"%@%@%@", [self.hostURL absoluteString],
                               [self.hostURL query] ? @"&" : @"?", queryString];
        
        
        
        url = [NSURL URLWithString:URLString];
    }
    
    ECSLogDebug(self.logger, @"Connecting to %@...", self.hostURL);
    
    self.webSocket = [[ECSWebSocket alloc] initWithURL:url];
    
    self.webSocket.delegate = self;
    
    [self.webSocket open];
    
    [self registerForActiveNotifications];
    
    return YES; 
}

-(void)appForegrounded:(NSNotification*)note {
    
    ECSLogDebug(self.logger, @"STOMP app active notification. wasConnected=%d, self.connected=%d.", _wasConnected, self.connected);
    
    if( _wasConnected ) {
        
        _wasConnected = NO;
        
        [self reconnect]; // STOMP CONNECT
        
    }
}

-(void)appBackgrounded:(NSNotification*)note {
    
    ECSLogDebug(self.logger, @"STOMP app inactive notification. wasConnected=%d, self.connected=%d.", _wasConnected, self.connected);
    
    self.isConnecting = NO;
    
    if( self.connected ) {
        
        _wasConnected = YES;
        
        [self _internal_disconnect]; // STOMP DISCONNECT
        
        [self.webSocket close];
        
    }
}

- (void) registerForActiveNotifications {
    
    [self unregisterForNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appForegrounded:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appBackgrounded:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}
- (void) unregisterForNotifications {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    
}

- (BOOL) reconnect {
    if ( self.hostURL ) {
        return [self connectToHost:[self.hostURL absoluteString]];
    } else {
        return NO;
    }
}

- (void)sendConnectToHost:(NSString*)host {
    
    NSAssert(host, @"Host must not be nil");
    
    ECSLogDebug(self.logger, @"STOMP connect. Host %@", host);
    
    NSDictionary *headers = @{
                              @"accept-version": kStompVersion,
                              @"host": host,
                              @"heart-beat": @"20000,20000"
                              };
    self.connected = NO;
    
    [self sendCommand:kStompConnect
          withHeaders:headers
              andBody:nil];
}

- (void)closeSocket {
    [self.webSocket close];
}

- (void)disconnect {
    
    [self _internal_disconnect];
    
    // These are done here because in the public function called by external sources.
    // Internally, we call disconnect when the app resigns active, in which case we want to receive these notifications still.

    ECSLogVerbose(self.logger, @"Removing app foreground notifications because Stomp has disconnected.");
    
    [self unregisterForNotifications];
}

- (void)_internal_disconnect {
    
    ECSLogVerbose(self.logger, @"Issuing STOMP disconnect.");
    
    [self invalidateHeartbeatTimer];
    
    self.connected = NO;

    _isConnecting = NO;
    
    [self sendCommand:kStompDisconnect withHeaders:nil andBody:nil];
}

- (void)setAuthToken:(NSString *)token {
    authToken = token;
}

- (void)subscribeToDestination:(NSString*)destination
            withSubscriptionID:(NSString*)subscriptionID
                    subscriber:(__weak id<ECSStompDelegate>)subscriber {
    
    ECSLogDebug(self.logger, @"Subscribing. Dest=%@, SubID=%@", destination, subscriptionID);
    
    NSMutableDictionary *headers = [[NSMutableDictionary alloc] init];
    
    headers[@"id"]                  = subscriptionID;
    headers[@"destination"]         = destination;
    
    // mas - Switched for 6.2.2 per meeting w/Russ,Ken. If ACK sends messageID, this should be -induvidual.
//    headers[@"ack"] = @"client";
    headers[@"ack"]                 = @"client-individual";
    
    headers[@"persistent"]          = @"true";
    headers[@"prefetch-count"]      = @"0"; // mas - Set to 0 as per Russ to avoid a barrage of agent messages out of order.
    
    headers[@"receipt"] = kStompReceiptID;
    
    if(authToken) {
        headers[@"x-humanify-auth"] = authToken;
    }
    
    self.subscribers[subscriptionID] = subscriber;
    
    [self sendCommand:kStompSubscribe
          withHeaders:headers
              andBody:nil];
}

- (void)unsubscribe:(NSString*)subscriptionID {
    
    if( !self.subscribed ) {
        
        ECSLogDebug(self.logger,@"Unsubscribe issued when no subscription active. Ignorring. SubID=%@", subscriptionID);
        
    } else {
        
        ECSLogDebug(self.logger,@"Unsubscribing. SubID=%@", subscriptionID);
        
        NSDictionary *headers = @{ @"id": subscriptionID, @"persistent": @"true" };
        
        if (self.subscribers[subscriptionID]) {
            [self.subscribers removeObjectForKey:subscriptionID];
        }
        
        self.subscribed = NO;
        
        [self sendCommand:kStompUnsubscribe
              withHeaders:headers
                  andBody:nil];
    }
}

- (void)sendAckForMessage:(NSString*)messageId
           andTransaction:(NSString*)transactionId {
    
    [self sendConfirmCommandType:kStompAck messageId:messageId transactionId:transactionId];
}

- (void)sendNackForMessage:(NSString*)messageId
            andTransaction:(NSString*)transactionId {
    
    [self sendConfirmCommandType:kStompNack messageId:messageId transactionId:transactionId];
}

- (void)sendConfirmCommandType:(NSString *)command messageId:(NSString *)messageId transactionId:(NSString *)transactionId {
    
    if( !self.subscribed ) {
        // An errant command issued after an unsubscribe. Ignoring.
        ECSLogVerbose(self.logger, @"Outbound %@ request but channel is unsubscribed. Dumping request.", command);
        return;
        
    } else {
        ECSLogVerbose(self.logger, @"Sending %@. MsgID=%@, TranID=%@", command, messageId, transactionId);
    }
    
    NSMutableDictionary *headers = [[NSMutableDictionary alloc]
                                    initWithDictionary:@{@"id": messageId}];
    
    if (transactionId) headers[@"transaction"] = transactionId;
    
    [self sendCommand:kStompAck
          withHeaders:headers
              andBody:nil];
}

- (void)startTransaction:(NSString*)transactionId {
    
    NSDictionary *headers = @{ @"transaction": transactionId };
    
    [self sendCommand:kStompBegin
          withHeaders:headers
              andBody:nil];
}

- (void)commitTransaction:(NSString*)transactionId {
    
    NSDictionary *headers = @{
                              @"transaction": transactionId
                              };
    [self sendCommand:kStompCommit withHeaders:headers andBody:nil];
}

- (void)abortTransaction:(NSString*)transactionId {
    
    NSDictionary *headers = @{
                              @"transaction": transactionId
                              };
    [self sendCommand:kStompAbort withHeaders:headers andBody:nil];
}

- (void)sendMessage:(NSString *)message
      toDestination:(NSString*)destination
        contentType:(NSString*)contentType
  additionalHeaders:(NSDictionary *)additionalHeaders {
    
    ECSLogVerbose(self.logger, @"Sending STOMP message=%@, Dest=%@, ContentType=%@, Headers=%@",
                  message, destination, contentType, additionalHeaders);
    
    NSAssert(destination, @"destination must exist");
    
    NSMutableDictionary *headers = [[NSMutableDictionary alloc] init];
    
    headers[@"destination"] = destination;
    
    if (contentType) {
        headers[@"content-type"] = contentType;
    }
    
    if(authToken) {
        headers[@"x-humanify-auth"] = authToken;
    }
    
    if (additionalHeaders) {
        [headers addEntriesFromDictionary:additionalHeaders];
    }
    
    [self sendCommand:kStompSend
          withHeaders:headers
              andBody:message];
}

- (void)sendCommand:(NSString*)command withHeaders:(NSDictionary*)headers andBody:(NSString*)body {
    
    NSMutableString *frame = [NSMutableString stringWithFormat:@"%@\n", command];
    
    if (headers) {
        
        NSMutableString *headerString = [NSMutableString new];
        
        for (NSString *key in headers.allKeys) {
            
            NSString *value = [self encodeStringEscapingCharacters:headers[key]];
            [headerString appendFormat:@"%@:%@\n", key, value];
        }
        
        [frame appendString:headerString];
    }
    
    [frame appendString:@"\n"];
    
    if (body) {
        [frame appendString:body];
    }
    
    [frame appendString:@"\x00"];
    
    ECSLogVerbose(self.logger, @"STOMP:\n\n%@\n\n", frame);
    
    [self.webSocket send:frame];
}

#pragma mark - Websocket Callbacks

- (void)webSocketDidOpen:(ECSWebSocket *)webSocket {
    
    ECSLogDebug(self.logger, @"Issuing CONNECT to %@", self.hostURL.host );
    
    [self sendConnectToHost:self.hostURL.host];
}

- (void)webSocket:(ECSWebSocket *)webSocket didFailWithError:(NSError *)error {
    
    ECSLogError(self.logger, @"ERROR - %@", error);
//    _isConnecting = NO;
    
//    if (error.code == 57) { // "Socket is not connected."
//
//        // Attempt a reconnect after 5 seconds.
//        [self performSelector:@selector(reconnect) withObject:nil afterDelay:5];
//
//    } else {
    
        self.connected = NO;
        self.isConnecting = NO;     // mas - 6.2.0 - A reconnect failure would prevent future reconnects from working. 
        
        [self.delegate stompClient:self didFailWithError:error];
//    }
}

- (void)webSocket:(ECSWebSocket *)webSocket didReceiveMessage:(id)message {
    
    ECSStompFrame *frame = [self decodeFrame:message];
    
    ECSLogVerbose(self.logger, @"\nMessage=%@\n\nFrame=%@\n", message, frame);

    // Any message from server indicates it is "good" reset server heartbeat miss count and "connecting" status.
    self.isConnecting = NO;
    _clientHeartbeatsMissed = 0;
    
    // Check for, and update heart-beat if applicable
    if (frame.headers && frame.headers[@"heart-beat"]) {
        [self updateHeartbeatFromHeader:frame.headers[@"heart-beat"]];
    }
    
    if ([frame.command isEqualToString:kStompConnected]) {
        
        self.connected = YES;
        
        if ([self.delegate respondsToSelector:@selector(stompClientDidConnect:)]) {
            
            [self.delegate stompClientDidConnect:self];
        }
        
    } else if ([frame.command isEqualToString:kStompReceipt]) {
    
        if( [frame.headers[@"receipt-id"] isEqualToString:kStompReceiptID]) {
            // This is the receiept for a Subscribe command.
            
            self.subscribed = YES;
            
        }
        
    } else if ([frame.command isEqualToString:kStompMessage]) {
        
        [self processMessageFrame:frame];
        
    } else if ([frame.command isEqualToString:kStompError]) {
        
        if( frame.headers.count > 0 && frame.headers[@"message"] ) {
            
            if( [frame.headers[@"message"] isEqualToString:@"Connection to broker closed."] ) {
                
                // This is the error seen after a proper DISCONNECT is issued. Supressing.
                
                ECSLogVerbose(self.logger, @"Supressing connection to broker closed error (we have already disconnected)."); 
                
                
            } else if ( [frame.headers[@"message"] isEqualToString:@"Processing error"] ) {
                
                // Probably message spam. A reconnect should fix this error.
                
                ECSLogError(self.logger, @"STOMP processing error. Attempting STOMP reconnect...");
                
                [self reconnect];
                
                
            } else {
                
                // Anything else send back to the host app / high level...
                
                NSError *newError = [NSError errorWithDomain:@"com.humanify"
                                                        code:ECS_ERROR_STOMP
                                                    userInfo:@{@"description": frame.headers[@"message"]}];
                
                if([self.delegate respondsToSelector:@selector(stompClient:didFailWithError:)]) {
                    
                    [self.delegate stompClient:self didFailWithError:newError];
                }
                
            }
            
        }
        
    } else if (frame.command.length == 0 && frame.headers.count == 0) {
        
        ECSLogVerbose(self.logger, @"Stomp heart-beat arrived from server.");
        
    }
}

- (void)webSocket:(ECSWebSocket *)webSocket didReceivePong:(NSData *)pongPayload {
    
    ECSLogVerbose(self.logger, @"WebSocket Pong: %@", pongPayload);
}

- (void)webSocket:(ECSWebSocket *)webSocket didCloseWithCode:(NSInteger)code
                                                      reason:(NSString *)reason
                                                    wasClean:(BOOL)wasClean {
    
    ECSLogDebug(self.logger, @"WebSocket closing. Code=%d, Reason=%@, wasClean=%d", code, reason, wasClean);
    
    self.isConnecting = NO;
    
    if( !wasClean ) {
        
        NSError *newError = [NSError errorWithDomain:ECSErrorDomainStomp
                                                code:code
                                            userInfo:@{@"description": reason}]; // @"Stream end encountered"
        
        if([self.delegate respondsToSelector:@selector(stompClient:didFailWithError:)]) {
            
            [self.delegate stompClient:self didFailWithError:newError];
        }
    } else {
        
        if( [self.delegate respondsToSelector:@selector(stompClientDidCloseWithCode:reason:)] ) {
            [self.delegate stompClientDidCloseWithCode:code reason:reason];
        }
        
    }
    
}

- (void)processMessageFrame:(ECSStompFrame*)frame {
    
    if (!frame.headers) {
        ECSLogError(self.logger, @"ERROR: Missing frame headers! Frame=%@", frame);
        return;
    }
    
    NSString *subscription = frame.headers[@"subscription"];
    
    if (subscription) {
        
        id<ECSStompDelegate> subscriber = self.subscribers[subscription];
        
        if (subscriber && [subscriber respondsToSelector:@selector(stompClient:didReceiveMessage:)]) {
            
            [subscriber stompClient:self didReceiveMessage:frame];
            
            NSString *messageId = frame.headers[@"message-id"];
            
            if (messageId) {
                
                [self sendAckForMessage:messageId andTransaction:frame.headers[@"transaction"]];
            }
            
        } else {
            
            NSString *messageId = frame.headers[@"message-id"];
            
            if (messageId) {
                [self sendNackForMessage:messageId andTransaction:frame.headers[@"transaction"]];
            }
        }
        
    } else {
        
        NSString *messageId = frame.headers[@"message-id"];
        
        if (messageId) {
            [self sendNackForMessage:messageId andTransaction:frame.headers[@"transaction"]];
        }
    }
}

#pragma mark - Frame encoding

- (ECSStompFrame*)decodeFrame:(NSString*)frameData {
    
    NSArray *frameComponents = [frameData componentsSeparatedByString:@"\n"];
    
    ECSStompFrame *frame = [ECSStompFrame new];
    
    if (frameComponents.count > 0) {
        
        frame.command = [frameComponents[0] copy];
        
        int i = 1;
        for (i = 1; i < frameComponents.count ; i++) {
            
            NSString *component = frameComponents[i];
            
            if (component.length == 0) {
                break;
            }
            
            NSArray *headerComponents = [component componentsSeparatedByString:@":"];
            
            if (headerComponents.count == 2) {
                
                NSString *key = [self decodeStringWithEscapedCharacters:headerComponents[0]];
                NSString *value = [self decodeStringWithEscapedCharacters:headerComponents[1]];
                
                frame.headers[key] = value;
                
            } else {
                ECSLogWarn(self.logger, @"Frame is missing header components.");
            }
            
        }
        
        i = i + 1; // Skip newline separator
        
        int j;
        NSMutableString *bodyString = [[NSMutableString alloc] init];
        
        for (j = i ; i < frameComponents.count ; i++) {
            [bodyString appendString:[frameComponents[i] stringByReplacingOccurrencesOfString:@"\x00" withString:@""]];
        }
        frame.body = [NSString stringWithString:bodyString];
    }
    
    return frame;
}

- (NSString*)encodeStringEscapingCharacters:(NSString*)header {
    
    NSString *encodedString = [header stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    encodedString = [encodedString stringByReplacingOccurrencesOfString:@":" withString:@"\\c"];
    encodedString = [encodedString stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    encodedString = [encodedString stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];

    return encodedString;
}

- (NSString*)decodeStringWithEscapedCharacters:(NSString*)encocdedString {
    
    NSString *decodedString = [encocdedString stringByReplacingOccurrencesOfString:@"\\c" withString:@":"];
    decodedString = [decodedString stringByReplacingOccurrencesOfString:@"\\\\" withString:@"\\"];
    decodedString = [decodedString stringByReplacingOccurrencesOfString:@"\\r" withString:@"\r"];
    decodedString = [decodedString stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
    
    return decodedString;
}

#pragma mark Client Heartbeating

-(void)updateHeartbeatFromHeader:(NSString *)theHeader {
    
    // We have a heartbeat value to check.
    // Will look like:    0,0  or  5000,0  or  0,5000
    NSArray *parts = [theHeader componentsSeparatedByString:@","];
    
    // The second value indicates how often the server expects a heartbeat from the client.
    if(parts[1]) _clientHeartbeatInterval = [parts[0] intValue];
    
    // NOTE: This will test heartbeat regardless of server setting.
    //_clientHeartbeatInterval = 5000;
    
    // If server indicates it wants a heartbeat. Fire up the timer!
    if (_clientHeartbeatInterval > 0) {
        
        [self startHeartbeatTimer];
    }
}

-(void) startHeartbeatTimer {
    
    [self invalidateHeartbeatTimer];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        HeartBeatTimerTarget *timerTarget = [[HeartBeatTimerTarget alloc] init];
        timerTarget.realTarget = self;
        self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:(_clientHeartbeatInterval/1000)
                                                               target:timerTarget
                                                             selector:@selector(doStompHeartbeat:)
                                                             userInfo:nil
                                                              repeats:NO];
    });
}

-(void)invalidateHeartbeatTimer {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if( self.heartbeatTimer ) {
            [self.heartbeatTimer invalidate];
            self.heartbeatTimer = nil;
        }
    });
}

-(void)doStompHeartbeat:(NSTimer *)timer {
    
    ECSLogVerbose(self.logger,@"Timer tick. Missed heartbeat count: %d", _clientHeartbeatsMissed);
    
    if( _clientHeartbeatsMissed >= 3 )
    {
        ECSLogDebug(self.logger, @"Server missed 3 heartbeats. Issuing a close.");
        self.connected = NO;
//        if( self.delegate && [self.delegate respondsToSelector:@selector(stompClientDidDisconnect:)])
//        {
//            [self.delegate stompClientDidDisconnect:self];
//        }

        [self.webSocket close]; // Should trigger a didCloseWithCode() callback.
        
        if( self.delegate && [self.delegate respondsToSelector:@selector(stompClientDidCloseWithCode:reason:)]) {
            [self.delegate stompClientDidCloseWithCode:ECSStatusNoStatusReceived reason:@"Heartbeat failure"];
        }
    }
    else if (self.webSocket.readyState == ECS_OPEN && self.connected && self.heartbeatTimer != nil)
    {
        _clientHeartbeatsMissed++;
        if( _clientHeartbeatsMissed > 1) {
            ECSLogVerbose(self.logger, @"Connection BAD. Pinging again in %d", _clientHeartbeatInterval);
        } else {
            ECSLogVerbose(self.logger, @"Connection good. Pinging again in %d", _clientHeartbeatInterval);
        }
        NSData *pingData = [[NSData alloc] initWithBytes:(unsigned char[]){0x0A} length:1];
        [self.webSocket sendPing:pingData];
        
        [self startHeartbeatTimer];
    }
    else
    {
        ECSLogDebug(self.logger, @"No more heartbeats because Stomp found disconnected.");
    }
}

@end

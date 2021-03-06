//
//  ECSStompClient.h
//  EXPERTconnect
//
//  Copyright (c) 2015 Humanify, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ECSStompClient;
@class ECSLog;

/**
 ECSStompFrame defines the basic frame structure for communicating over the STOMP protocol.
 */
@interface ECSStompFrame : NSObject

// The STOMP command type
@property (strong, nonatomic) NSString* command;

// Dictionary of STOMP headers to be used with the command
@property (strong, nonatomic) NSMutableDictionary *headers;

// The optional body for the command
@property (strong, nonatomic) NSString *body;

@end



/**
 The ECSStompDelegate defines methods that are called when asynchronous STOMP messages are 
 received.
 */
@protocol ECSStompDelegate <NSObject>

@optional

/**
 Called when the STOMP client receives a CONNECTED message from the server.
 
 @param stompClient the reference to the client that received the CONNECTED message
 */
- (void)stompClientDidConnect:(ECSStompClient *)stompClient;

- (void)stompClientDidDisconnect:(ECSStompClient *)stompClient;

- (void)stompClientDidCloseWithCode:(NSInteger)code reason:(NSString *)reason;

/**
 Called when the STOMP client fails to connect.
 
 @param stompClient the client that received the error message.
 @param error the error returned by the server
 */
- (void)stompClient:(ECSStompClient *)stompClient didFailWithError:(NSError *)error;

/**
 Called when the STOMP client receives a MESSAGE type.
 
 @param stompClient the client that received the message.
 @param message the STOMP frame containing the message.
 */
- (void)stompClient:(ECSStompClient *)stompClient didReceiveMessage:(ECSStompFrame*)message;

@end




/**
 The ECSStompClient implements the base level STOMP protocol as defined by https://stomp.github.io/.
 This client connects via a websocket to the specified host.
 */
@interface ECSStompClient : NSObject

// Indicates if the client is currently connected.
@property (assign, nonatomic) BOOL connected;

// Indicates if the client is currently connected.
@property (assign, nonatomic) BOOL isConnecting;

// Indicates if the client is currently subscribed.
@property (assign, nonatomic) BOOL subscribed;

// The delegate for receiving asynchronous messages.
@property (weak, nonatomic) id<ECSStompDelegate> delegate;

@property (strong, nonatomic) NSString *authToken;

@property (strong, nonatomic) NSTimer *heartbeatTimer;

@property (nonatomic, strong) ECSLog *logger;

@property (strong, nonatomic) NSURL *hostURL;

- (NSString *)readyStateString;

/**
 Connect to the specified STOMP host.  Upon successful connection the ECSStompDelegate will be sent 
 the stompClientDidConnect: message
 
 @param host A URL specifying where the Humanify API is running an active Stomp instance.
 */
- (BOOL) connectToHost:(NSString*)host;

- (void)closeSocket;

/**
 Disconnect from the current host
 */
- (void)disconnect;

/** 
 Reconnect the Stomp connection using previous conversationID, subscriptionID, etc.
 */
- (BOOL) reconnect;

/**
 Manually set the auth token.
 
 @param token The auth token string. See https://jwt.io for examples.
 */
- (void)setAuthToken:(NSString *)token;

/**
 Subscribe for asynchronous messages on the specified destination with the given subscriber ID.
 
 @param destination A URL to the Humanify API for subscribing to a Stomp channel. Usually contains "%host_URL%/topic/conversations.%conversationID%"
 @param subscriptionID A unique identifier for the subscription to the channel. Usually given out in a Stomp CONNECT packet.
 @param subscriber the ECSStompDelegate used to receive messages.
 */
- (void)subscribeToDestination:(NSString*)destination
            withSubscriptionID:(NSString*)subscriptionID
                    subscriber:(__weak id<ECSStompDelegate>)subscriber;

/** 
 Unsubscribes from messages using the given subscription ID
 
 @param subscriptionID unique identifier to the subscription we are unsubscribing from.
 */
- (void)unsubscribe:(NSString*)subscriptionID;

/**
 Sends an ACK message to the STOMP server.
 
 @param messageId unique identifier pointing to the Stomp message to ACK
 @param transactionId the optional transaction identifier to ACK
 */
- (void)sendAckForMessage:(NSString*)messageId andTransaction:(NSString*)transactionId;

/**
 Sends a NACK message to the STOMP server.
 
 @param messageId the message identifier to NCK
 @param transactionId the optional transaction identifier to NACK
 */
- (void)sendNackForMessage:(NSString*)messageId andTransaction:(NSString*)transactionId;

/**
 Starts a STOMP transaction with the specified transaction ID.
 
 @param transactionId the identifier of the transaction to start
 */
- (void)startTransaction:(NSString*)transactionId;

/**
 Commits a STOMP transaction with the specified transaction ID.
 
 @param transactionId the identifier of the transaction to commit
 */
- (void)commitTransaction:(NSString*)transactionId;

/**
 Aborts a STOMP transaction with the specified transaction ID.
 
 @param transactionId the identifier of the transaction to abort
 */
- (void)abortTransaction:(NSString*)transactionId;

/**
 Sends a message to the specified destination using the specified contentType
 
 @param message the UTF-8 encoded message to send
 @param destination the destination to send the message to
 @param contentType the content type of the message (usually text/plain)
 @param additionalHeaders any additional STOMP headers to add to the message
 */
- (void)sendMessage:(NSString *)message
      toDestination:(NSString*)destination
        contentType:(NSString*)contentType
  additionalHeaders:(NSDictionary *)additionalHeaders;

@end

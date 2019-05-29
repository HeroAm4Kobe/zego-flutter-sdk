import 'dart:async';
import 'package:flutter/services.dart';
import 'zego_api_defines.dart';
import 'zego_liveroom_event_channel.dart';

class ZegoLiveRoomPlugin {
  /* Method Channel */
  static const MethodChannel _channel =
  const MethodChannel('plugins.zego.im/zegoliveroom_plugin');

  ///ZegoLiveRoom SDK 版本号
  ///
  ///@return 版本号
  ///@discussion 开发者使用本 API 获取 SDK 版本号
  static Future<String> getSdkVersion() async {
    final String version = await _channel.invokeMethod('getSdkVersion');
    return version;
  }

  ///ZegoLiveRoom 引擎版本号
  ///
  ///@return 引擎版本号
  ///开发者使用本 API 获取 引擎 版本号
  static Future<String> getEngineVersion() async {
    final String version = await _channel.invokeMethod('getEngineVersion');
    return version;
  }

  ///初始化 SDK
  ///
  ///@param appID  Zego 派发的数字 ID，开发者的唯一标识
  ///@param appSign  Zego 派发的签名，用来校验对应 appID 的合法性，共 32 位，以逗号隔开。如: '0x01,0x02,...,0xff'
  ///@return 错误码，0 代表初始化成功
  ///@discussion 初始化 SDK 时调用。初始化 SDK 失败可能导致 SDK 功能异常
  static Future<int> initSDK(int appID, String appSign) async {
    final int errorCode = await _channel.invokeMethod('initSDK', {
      'appID': appID,
      'appSign': appSign
    });

    return errorCode;
  }

  ///反初始化 SDK，释放资源
  ///
  ///@return true 成功，false 失败
  ///@discussion 释放 SDK 资源
  static Future<bool> uninitSDK() async {
    final bool success = await _channel.invokeMethod('uninitSDK');
    return success;
  }

  ///设置用户 ID 及用户名
  ///
  ///@param userID 用户 ID，不可为空
  ///@param userName 用户名，不可为空
  ///@return true 成功，false 失败
  ///@discussion 确保在 [loginRoom] 前设置成功。userID 和 userName 由业务方自己控制
  static Future<bool> setUser(String userID, String userName) async {
    final bool success = await _channel.invokeMethod('setUser', {
      'userID': userID,
      'userName': userName
    });

    return success;
  }

  ///是否打开调试信息
  ///
  ///@param enable 是否打开调试信息，true 打开，false 不打开。默认为 false
  ///@discussion 建议在初始化 SDK 前调用。建议在调试阶段打开此开关，方便调试
  static Future<void> setVerbose(bool enable) async {
    return await _channel.invokeMethod('setVerbose', {
      'enable': enable
    });

  }

  ///是否启用测试环境
  ///
  ///@param enable 是否启用测试环境，true 启用，false 不启用。默认为 false
  ///@discussion 建议在初始化 SDK 前调用。建议开发者在开发阶段设置为测试环境，使用由 Zego 提供的测试环境。上线前需切换为正式环境运营
  static Future<void> setUseTestEnv(bool enable) async {
    return await _channel.invokeMethod('setUseTestEnv', {
      'enable': enable
    });
  }

  ///上报日志
  ///
  ///@discussion 上传日志到后台便于分析问题
  ///@discussion 在初始化 SDK 成功后调用
  static Future<void> uploadLog() async {
    return await _channel.invokeMethod('uploadLog');

  }

  ///获取 SDK 日志本地存放路径
  ///
  ///@return 日志本地存放路径
  ///@discussion 获取日志路径可用于展示、提取或分享等操作
  static Future<String> getLogDir() async {
    final path = await _channel.invokeMethod('getLogDir');
    return path;
  }

  ///设置房间配置信息
  ///
  ///@param audienceCreateRoom 观众是否可以创建房间。true 可以，false 不可以。默认 true
  ///@param userStateUpdate 用户状态（用户进入、退出房间）是否广播。true 广播，false 不广播。默认 false
  ///@return true 成功，false 失败
  ///@discussion 在 userStateUpdate 为 true 的情况下，用户进入、退出房间会触发 [_onUserUpdate] 回调
  static Future<void> setRoomConfig(bool audienceCreateRoom, bool userStateUpdate) async {
    return await _channel.invokeMethod('setRoomConfig', {
      'audienceCreateRoom':audienceCreateRoom,
      'userStateUpdate': userStateUpdate
    });

  }

  ///登录房间
  ///
  ///@param roomID 房间 ID，长度不可超过 255 byte
  ///@param roomName 房间名称，可选，长度不可超过 255 byte
  ///@param role 成员角色，可取值为 ZEGO_ANCHOR（主播），ZEGO_AUDIENCE（观众），详见 [ZegoRoomRole] 定义
  ///@return 房间流信息，其中 errorCode 为 0 代表登录房间成功，参考 [ZegoLoginRoomResult] 定义
  ///@discussion 登录房间成功，才能开始直播
  static Future<ZegoLoginRoomResult> loginRoom(String roomID, String roomName, int role) async {
    final Map<dynamic, dynamic> mapResult = await _channel.invokeMethod('loginRoom', {
      'roomID': roomID,
      'roomName': roomName,
      'role': role
    });

    List<ZegoStreamInfo> streamList = [];
    final List<dynamic> nativeList = mapResult['streamList'];

    for(var stream in nativeList) {
      ZegoStreamInfo streamInfo = new ZegoStreamInfo(stream['userID'], stream['userName'], stream['streamID'], stream['extraInfo']);
      streamList.add(streamInfo);
    }

    ZegoLoginRoomResult result = new ZegoLoginRoomResult(mapResult['errorCode'], streamList);

    return result;
  }

  ///退出房间
  ///
  ///@return true 成功，false 失败
  ///@discussion 连麦情况下，要 stop 所有的 stream 后，才能执行 logoutRoom。
  static Future<bool> logoutRoom() async {
    final bool success = await _channel.invokeMethod('logoutRoom');
    return success;
  }

  ///发送自定义信令
  ///
  ///@param memberList 发送对象列表
  ///@param content 消息内容。长度不超过 2048 字节
  ///@return 自定义信令发送结果，参考 [ZegoCustomCommandResult] 定义
  ///@discussion 信令内容由用户自定义
  static Future<ZegoCustomCommandResult> sendCustomCommand(List<ZegoUser> userList, String content) async {
    List<Map<String, String>> objUserList = [];
    for(var user in userList) {
      Map<String, String> objUser = user.toMap();
      objUserList.add(objUser);
    }

    final Map<dynamic, dynamic> mapResult = await _channel.invokeMethod('sendCustomCommand', {
      'users': objUserList,
      'content': content
    });

    ZegoCustomCommandResult result = new ZegoCustomCommandResult(mapResult['errorCode'], mapResult['roomID']);

    return result;
  }

  ///暂停模块
  ///
  ///@param type 模块类型，参考 [ZegoApiModule] 定义
  ///@discussion 用于需要暂停指定模块的场合，例如来电时暂定音频模块。暂停指定模块后，注意在合适时机下恢复模块
  static Future<void> pauseModule(int type) async {
    return await _channel.invokeMethod('pauseModule', {
      'type' : type
    });

  }

  ///恢复模块
  ///
  ///@param type 模块类型，参考 [ZegoApiModule] 定义
  ///@discussion 用于需要恢复指定模块的场合，例如来电结束后恢复音频模块。暂停指定模块后，注意在合适时机下恢复模块
  static Future<void> resumeModule(int type) async {
    return await _channel.invokeMethod('resumeModule', {
      'type' : type
    });

  }

  ///设置是否允许SDK使用麦克风设备
  ///
  ///@param enable YES 表示允许使用麦克风，NO 表示禁止使用麦克风，此时如果SDK在占用麦克风则会立即释放。
  ///@return true 成功 false 失败
  ///@discussion 调用时机为引擎创建后的任意时刻。
  ///@note 接口由于涉及对设备的操作，极为耗时，不建议随便调用，只在真正需要让出麦克风给其他应用的时候才调用
  static Future<bool> enableMicDevice(bool enable) async {
    final bool success = await _channel.invokeMethod('enableMicDevice', {
      'enable': enable
    });

    return success;
  }

  ///设置回调对象
  ///
  ///@param onStreamUpdated 设置接收 流信息更新 回调，参考 [_onStreamUpdated] 定义
  ///@param onStreamExtraInfoUpdated 设置接收 流附加信息更新 回调，参考 [_onStreamExtraInfoUpdated] 定义
  ///@param onTempBroken 设置接收 server 连接中断 回调，参考 [_onTempBroken] 定义
  ///@param onReconnect 设置接收 server 重连成功 回调，参考 [_onReconnect] 定义
  ///@param onDisconnect 设置接收 server 断开 回调，参考 [_onDisconnect] 定义
  ///@param onReceiveCustomCommand 设置接收 收到自定义消息 回调，参考 [_onReceiveCustomCommand] 定义
  ///@param onUserUpdate 设置接收 房间成员更新 回调，参考 [_onUserUpdate] 定义
  ///@param onLiveEvent 设置接收 直播事件 回调，参考 [_onLiveEvent] 定义
  ///@param onAVEngineStart 设置接收 音视频引擎开始 回调，参考 [_onAVEngineStart] 定义
  ///@param onAVEngineStop 设置接收 音视频引擎停止 回调，参考 [_onAVEngineStop] 定义
  ///@discussion 开发者只有调用本 API 设置回调对象才能收到相关回调
  static void registerRoomCallback({
    Function(int type, List<ZegoStreamInfo> streamList, String roomID) onStreamUpdated,
    Function(List<ZegoStreamInfo> streamList, String roomID) onStreamExtraInfoUpdated,
    Function(int errorCode, String roomID) onTempBroken,
    Function(int errorCode, String roomID) onReconnect,
    Function(int errorCode, String roomID) onDisconnect,
    Function(int reason, String roomID) onKickOut,
    Function(String fromUserID, String fromUserName, String content, String roomID) onReceiveCustomCommand,
    Function(List<ZegoUserInfo> userList, int updateType) onUserUpdate,
    Function(int event, Map<String, String> info) onLiveEvent,
    Function() onAVEngineStart,
    Function() onAVEngineStop
}) {

    _onStreamUpdated = onStreamUpdated;
    _onStreamExtraInfoUpdated = onStreamExtraInfoUpdated;
    _onTempBroken = onTempBroken;
    _onReconnect = onReconnect;
    _onDisconnect = onDisconnect;
    _onKickOut = onKickOut;
    _onReceiveCustomCommand = onReceiveCustomCommand;
    _onUserUpdate = onUserUpdate;
    _onLiveEvent = onLiveEvent;
    _onAVEngineStart = onAVEngineStart;
    _onAVEngineStop = onAVEngineStop;

    if(_streamSubscription == null) {
      _streamSubscription = ZegoLiveRoomEventChannel.listenRoomEvent().listen(_eventListener);
    }

  }

  ///销毁回调对象
  ///
  ///@discussion 当开发者不再需要接收回调时，必须显式调用本 API 销毁回调对象
  static void unregisterRoomCallback() {

    _onStreamUpdated = null;
    _onStreamExtraInfoUpdated = null;
    _onTempBroken = null;
    _onReconnect = null;
    _onDisconnect = null;
    _onKickOut = null;
    _onReceiveCustomCommand = null;
    _onUserUpdate = null;
    _onLiveEvent = null;
    _onAVEngineStart = null;
    _onAVEngineStop = null;

    _streamSubscription?.cancel();
    _streamSubscription = null;

  }


  ///流信息更新
  ///
  ///@param type 更新类型，详见 [ZegoStreamUpdateType] 定义
  ///@param streamList 直播流列表，列表中包含的是变更流的信息，非房间全部流信息
  ///@param roomID 房间 ID
  ///@discussion 房间内增加流、删除流，均会触发此更新。主播推流，自己不会收到此回调，房间内其他成员会收到。建议对流增加和流删除分别采取不同的处理。
  ///@discussion 开发者必须调用 [registerRoomCallback] 且设置 onStreamUpdated 对象参数之后才能收到该回调
  static void Function(int type, List<ZegoStreamInfo> streamList, String roomID) _onStreamUpdated;

  ///流附加信息更新
  ///
  ///@param streamList 附加信息更新的流列表
  ///@param roomID 房间 ID
  ///@discussion 主播推流成功后调用 ZegoLiveRoomPublisherPlugin.updateStreamExtraInfo 更新附加信息，在此回调中通知房间内其他成员。调用 ZegoLiveRoomPublisherPlugin.updateStreamExtraInfo 更新信息的调用方，不会收到此回调
  ///@discussion 开发者必须调用 [registerRoomCallback] 且设置 onStreamExtraInfoUpdated 对象参数之后才能收到该回调
  static void Function(List<ZegoStreamInfo> streamList, String roomID) _onStreamExtraInfoUpdated;

  ///与 server 连接中断通知，SDK会尝试自动重连
  ///
  ///@param errorCode 错误码，0 表示无错误
  ///@param roomID 房间 ID
  ///@discussion 开发者必须调用 [registerRoomCallback] 且设置 onTempBroken 对象参数之后才能收到该回调
  static void Function(int errorCode, String roomID) _onTempBroken;

  /// 与 server 重连成功通知
  ///
  ///@param errorCode 错误码，0 表示无错误
  ///@param roomID 房间 ID
  ///@discussion 开发者必须调用 [registerRoomCallback] 且设置 onReconnect 对象参数之后才能收到该回调
  static void Function(int errorCode, String roomID) _onReconnect;

  ///与 server 断开通知
  ///
  ///@param errorCode 错误码，0 表示无错误
  ///@param roomID 房间 ID
  ///@discussion 建议开发者在此通知中进行重新登录、推/拉流、报错、友好性提示等其他恢复逻辑。与 server 断开连接后，SDK 会进行重试，重试失败抛出此错误。请注意，此时 SDK 与服务器的所有连接均会断开
  ///@discussion 开发者必须调用 [registerRoomCallback] 且设置 onDisconnect 对象参数之后才能收到该回调
  static void Function(int errorCode, String roomID) _onDisconnect;

  ///用户被踢出房间
  ///
  ///@param reason 被踢出原因，16777219 表示该账户多点登录被踢出，16777220 表示该账户是被手动踢出，16777221 表示房间会话错误被踢出。
  ///@param roomID 房间 ID
  ///@discussion 可在该回调中处理用户被踢出房间后的下一步处理（例如报错、重新登录提示等）
  ///@discussion 开发者必须调用 [registerRoomCallback] 且设置 onKickOut 对象参数之后才能收到该回调
  static void Function(int reason, String roomID) _onKickOut;

  ///收到自定义消息
  ///
  ///@param fromUserID 消息来源 UserID
  ///@param fromUserName 消息来源 UserName
  ///@param content 消息内容
  ///@param roomID 房间 ID
  ///@discussion 调用 [sendCustomCommand] 发送自定义消息后，消息列表中的用户会收到此通知
  ///@discussion 开发者必须调用 [registerRoomCallback] 且设置 onReceiveCustomCommand 对象参数之后才能收到该回调
  static void Function(String fromUserID, String fromUserName, String content, String roomID) _onReceiveCustomCommand;

  ///房间成员更新回调
  ///
  ///@param userList 成员更新列表
  ///@param type  更新类型，参考 [ZegoUserUpdateType] 定义(增量，全量)
  ///@discussion 用户调用 [setRoomConfig] 开启用户状态（用户进入、退出房间）广播，当房间成员变化（例如用户进入、退出房间）时，会触发此通知
  ///@discussion 开发者必须调用 [registerRoomCallback] 且设置 onUserUpdate 对象参数之后才能收到该回调
  static void Function(List<ZegoUserInfo> userList, int updateType) _onUserUpdate;

  ///直播事件回调
  ///
  ///@param event 直播事件状态，参考 [ZegoLiveEvent] 定义
  ///@param info 信息
  ///@discussion 设置直播事件回调对象后，在此回调中获取直播事件状态
  ///@discussion 开发者必须调用 [registerRoomCallback] 且设置 onLiveEvent 对象参数之后才能收到该回调
  static void Function(int event, Map<String, String> info) _onLiveEvent;

  ///音视频引擎开始时回调
  ///
  ///@discussion 设置音视频引擎开始时回调对象后，在此回调中获取音视频引擎开始的时机
  ///@discussion 开发者必须调用 [registerRoomCallback] 且设置 onAVEngineStart 对象参数之后才能收到该回调
  static void Function() _onAVEngineStart;

  ///音视频引擎停止时回调
  ///
  ///@discussion 设置音视频引擎停止时回调对象后，在此回调中获取音视频引擎停止的时机
  ///@discussion 开发者必须调用 [registerRoomCallback] 且设置 onAVEngineStop 对象参数之后才能收到该回调
  static void Function() _onAVEngineStop;




  /// 用于接收native层事件流，开发者无需关注
  static StreamSubscription<dynamic> _streamSubscription;
  /// 用于处理native层事件流，开发者无需关注
  static void _eventListener(dynamic data) {

    final Map<dynamic, dynamic> args = data;
    switch (args['name']) {
      case 'onStreamUpdated':
        if(_onStreamUpdated != null) {

          int type = args['updateType'];
          String roomID = args['roomID'];
          List<ZegoStreamInfo> streamList = [];
          List<dynamic> objList = args['streamList'];
          for (Map<dynamic, dynamic> obj in objList) {

            ZegoStreamInfo info = new ZegoStreamInfo(obj['userID'], obj['userName'], obj['streamID'], obj['extraInfo']);
            streamList.add(info);
          }

          _onStreamUpdated(type, streamList, roomID);
        }
        break;
      case 'onStreamExtraInfoUpdated':
        if(_onStreamExtraInfoUpdated != null) {

          String roomID = args['roomID'];
          List<ZegoStreamInfo> streamList = [];
          List<dynamic> objList = args['streamList'];
          for (Map<dynamic, dynamic> obj in objList) {

            ZegoStreamInfo info = new ZegoStreamInfo(obj['userID'], obj['userName'], obj['streamID'], obj['extraInfo']);
            streamList.add(info);
          }

          _onStreamExtraInfoUpdated(streamList, roomID);

        }
        break;
      case 'onTempBroken':
        if(_onTempBroken != null) {

          int errorCode = args['errorCode'];
          String roomID = args['roomID'];

          _onTempBroken(errorCode, roomID);

        }
        break;
      case 'onReconnect':
        if(_onReconnect != null) {

          int errorCode = args['errorCode'];
          String roomID = args['roomID'];

          _onReconnect(errorCode, roomID);

        }
        break;
      case 'onDisconnect':
        if(_onDisconnect != null) {

          int errorCode = args['errorCode'];
          String roomID = args['roomID'];

          _onDisconnect(errorCode, roomID);

        }
        break;
      case 'onKickOut':
        if(_onKickOut != null) {

          int reason = args['reason'];
          String roomID = args['roomID'];

          _onKickOut(reason, roomID);

        }
        break;
      case 'onUserUpdate':
        if(_onUserUpdate != null) {

          int updateType = args['updateType'];
          List<ZegoUserInfo> userList = [];
          List<dynamic> objList = args['userList'];
          for (Map<dynamic, dynamic> obj in objList) {

            ZegoUserInfo info = new ZegoUserInfo(obj['userID'], obj['userName'], obj['updateFlag'], obj['role']);
            userList.add(info);
          }

          _onUserUpdate(userList, updateType);
        }
        break;
      case 'onLiveEvent':
        if(_onLiveEvent != null) {

          int event = args['event'];
          Map<dynamic, dynamic> objMap = args['info'];
          Map<String, String> info = {};
          objMap.forEach((key, value) {
            String strKey = key;
            String strValue = value;

            info[strKey] = strValue;
          });

          _onLiveEvent(event, info);

        }
        break;
      case 'onReceiveCustomCommand':
        if(_onReceiveCustomCommand != null) {

          String fromUserID = args['userID'];
          String fromUserName = args['userName'];
          String content = args['content'];
          String roomID = args['roomID'];

          _onReceiveCustomCommand(fromUserID, fromUserName, content, roomID);
        }
        break;
      case 'onAVEngineStart':
        if(_onAVEngineStart != null) {

          _onAVEngineStart();

        }
        break;
      case 'onAVEngineStop':
        if(_onAVEngineStop != null) {

          _onAVEngineStop();

        }
        break;
      default:
        break;
    }

  }

}
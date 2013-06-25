package manager.connection
{
	import com.netease.protobuf.Message;
	
	import command.appCommand.SocketMsgFacade;
	
	import frame.command.AppNotification;
	import frame.command.BaseNotification;
	import frame.command.cmdInterface.INotification;
	
	import net.CommandInteractType;
	import net.ProtoIndexMap;
	
	import netWork.SocketMessage;
	
	import utils.console.errorCh;
	import utils.console.infoCh;

	/**
	 * 连接管理器 
	 * @author songdu.greg
	 * 
	 */	
	public class ConnectionManagerDelegate
	{
		private var _manager:ConnectionManager;
		
		private static var _instance:ConnectionManagerDelegate = null;
		
		private var _msgFacade:SocketMsgFacade = SocketMsgFacade.instance;
//==============================================================================
// Public Functions
//==============================================================================
		public function ConnectionManagerDelegate(code:$)
		{
			
		}	
		
		public static function get instance():ConnectionManagerDelegate
		{
			return _instance ||= new ConnectionManagerDelegate(new $);
		}
		
		/**
		 * 初始化委托
		 * @param	connectionManager	*	连接管理器
		 */
		public function init(connectionManager:*):void
		{
			this._manager = ConnectionManager(connectionManager);
		}
		
		/**
		 * 连接响应
		 * @param	value	Boolean	连接成功
		 */
		public function responseConnected(value:Boolean):void
		{
			var note:AppNotification = null;
			//连接成功
			if (value)
			{
				note = _manager.createNote(CommandInteractType.RESPONSE_CONNECTED_SUCCESS_COMMAND);
			}
			else//连接失败
			{
				note = _manager.createNote(CommandInteractType.RESPONSE_CONNECTED_FAIL_COMMAND);
				this.closeConnect();
			}
			note.dispatch();
			
		}
		/**
		 * 请求超时 
		 * 
		 */		
		public function connectTimeOut():void
		{
			var note:AppNotification = _manager.createNote(CommandInteractType.CONNECT_TIME_OUT_COMMAND);
			note.dispatch();
		}
		
		/**
		 * 状态错误 
		 * 
		 */		
		public function connectCallBackError():void
		{
			var note:AppNotification = _manager.createNote(CommandInteractType.CONNECT_CALL_BACK_STATUS_ERROR_COMMAND);
			note.dispatch();
		}
		
		/**
		 * 请求连接
		 * @param	host	String	服务器
		 * @param	port	port	端口
		 */
		public function socketConnectDelegate(host:String, port:int):void
		{
			if(null == _manager)
				_manager = ConnectionManager.instance;
			this._manager.socketConnection(host, port);
		}
		
		public function sendData(data:Object):void
		{
			this._manager.send(data);
		}
		
		public function closeConnect():void
		{
			this._manager.closeConnect();
		}
		
		
		/**
		 * 分发socket返回消息 
		 * @param message
		 * 
		 */		
		public function distributionSocketMsg(message:SocketMessage):void
		{
			if(message)
			{
				var msgName:String 
					= ProtoIndexMap.instance.getProtoNameByIndex(message.cmdIndex);	
				CONFIG::DEBUG
				{
					trace("<<<<<<<<<<");
//					infoCh("socket get msg", message.cmdIndex + " " + msgName);					
					trace("\tsocket get msg:"+message.cmdIndex + " " + msgName);
					trace("\tmessage cmd index:"+ message.cmdIndex);
					trace("\tmessage data length:" + message.dataBytes.length)
					//					trace("\tmessage data:"+ ByteArraryUtil.toHex(message.dataBytes));
				}
				
				//实例化返回内容
				message.dataBytes.position = 0;
				var instance:Message = _msgFacade.instanceMsgByType(message.cmdIndex);
				if(instance)
				{
					instance.mergeFrom(message.dataBytes);	
					var notification:INotification = new BaseNotification();
					notification.data = instance;
					
					//分发通知
					msgName = msgName.replace("Ack", "");
					var commandType:String = "S2C_" + msgName.toUpperCase() + "_ACK_COMMAND";
					var note:AppNotification = new AppNotification(commandType, notification);
					note.dispatch();
				}
				else
				{
					errorCh("socketMsg cannot be instantiated", message.cmdIndex);
				}
			}
			else
			{
				errorCh("socet data error", "null");
			}
		}
//------------------------------------------------------------------------------
// Private
//------------------------------------------------------------------------------

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Event
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-	
	}
}

class ${}
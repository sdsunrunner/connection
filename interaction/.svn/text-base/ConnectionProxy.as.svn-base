package manager.connection.interaction
{
	import com.netease.protobuf.Message;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import net.ProtoIndexMap;
	
	import netWork.SocketConnection;
	import netWork.event.ConnectionEvent;
	import netWork.event.SocketDataEvent;
	
	import utils.console.errorCh;
	import utils.console.infoCh;
	import utils.md5.MD5_Bytearray;
	import utils.proto.ProtoClassMapUtil;
	
	/**
	 * 连接代理器 
	 * @author songdu.greg
	 * 
	 */	
	public class ConnectionProxy extends EventDispatcher
	{
		private var _socket:SocketConnection;	
		/**
		 * 连接类型重复设置错误信息 
		 */		
		private static const ERROR_ALREADY_SET_CONNECTION_TYPE:String = "It has been already set the connection type. Don't need set again.";
		
		
		private var _reqTimer:Timer = null;//请求超时
		private static const WAIT_TIME_OUT:Number = 30;//Socket 超时时间
		private var _waitSeconds:Number = 0;//等待时间
		
		private static const HEARTBEAT_CMDID:Number = 40008;
		//==============================================================================
		// Public Functions
		//==============================================================================
		public function ConnectionProxy(target:IEventDispatcher=null)
		{
			super(target);
			_reqTimer = new Timer(1000);
		}
		
		/**
		 * 只有socket模式下需要执行connect
		 * @param	host	String	主机地址
		 * @param	port	int		端口
		 */
		public function socketConnect(host:String, port:int = 0):void
		{
			if(null == this._socket)
			{
				this._socket = new SocketConnection();
				this.addListenerConnection(this._socket);
			}
				
			this._socket.connect(host, port);
		}
		
		/**
		 * 以google序列化形式发送数据 
		 * @param message
		 * 
		 */		
		public function sendProtoBufData(obj:Object):void
		{
			var protoBufData:Message = obj as Message;
			if(protoBufData)
			{
				//从socket发送
				var className:String = ProtoClassMapUtil.getClassName(protoBufData);
				className = className.replace("Req", "");
				var cmdIndex:Number = ProtoIndexMap.instance.getProtoIndexByName(className);
				
				var dataBytes:ByteArray = new ByteArray();
				protoBufData.writeTo(dataBytes);
				
				var isCompress:int = 0;
				if(dataBytes.length > 1024)
				{
					dataBytes.compress();
					isCompress = 1;
				}
					
				var contentLen:int = dataBytes.length;
				var isEncrypt:int = 1;
				
				var version:int = 3;
				var cmdID:int = int(cmdIndex);
				
				//head
				var bytes:ByteArray = new ByteArray();
				setIntTo4byte(bytes, bytes.position, contentLen);
				setIntTo4byte(bytes, bytes.position, isEncrypt);
				setIntTo4byte(bytes, bytes.position, isCompress);
				setIntTo4byte(bytes, bytes.position, version);
				setIntTo4byte(bytes, bytes.position, cmdID);
				
				//MD5
				var md5:MD5_Bytearray = new MD5_Bytearray();
				var tempBytes:ByteArray = md5.hash(dataBytes);
				bytes.writeBytes(tempBytes, 0, tempBytes.length);
				
				//data
				bytes.writeBytes(dataBytes, 0, contentLen);
				
				CONFIG::DEBUG
				{
					if(cmdIndex != HEARTBEAT_CMDID)
					{
						infoCh("send msg cmd",cmdIndex +" "+ className);
						trace(">>>>>>>>>>");
						trace("\tsend msg cmd:"+ cmdIndex +" "+ className);
					}
				}				
				
				_socket.sendProtoBufMessage(bytes);
				if(cmdIndex != HEARTBEAT_CMDID)
				{
					_reqTimer.start();
					_waitSeconds = 0;
				}
			}
		}
		
		/**
		 * 关闭连接
		 */
		public function close():void
		{			
			if(this._socket)
			{
				this.removeListenerConnection(this._socket);
				this._socket.dispose();
				this._socket = null;	
			}	
		}
		
		/**
		 * 是否已经连接
		 * @return	Boolean	连接成功
		 */
		public function get connected():Boolean
		{
			var result:Boolean = false;
			if (null != this._socket)
			{
				result = this._socket.connected;
			}
			return result;
		}
		//------------------------------------------------------------------------------
		// Private
		//------------------------------------------------------------------------------
		private function addListenerConnection(connection:IEventDispatcher):void
		{
			connection.addEventListener(ConnectionEvent.CONNECTION_CONNECTED, onConnected);
			connection.addEventListener(ConnectionEvent.CONNECTION_CONNECT_FAIL, onConnectFail);
			connection.addEventListener(ConnectionEvent.CONNECTION_SECURITY_ERROR, onConnectSecurityError);
			
			connection.addEventListener(ConnectionEvent.CONNECTION_CONNECT_CLOSE, onConnectClose);
			
			connection.addEventListener(ConnectionEvent.CALL_BACK_STATUS_ERROR, onConnectCallBackStatusError);
			connection.addEventListener(SocketDataEvent.SOCKET_MESSAGE_EVENT, socketDataDistributionHandler);
			
			_reqTimer.addEventListener(TimerEvent.TIMER,checkTimeoutHandler);
		}
		
		private function removeListenerConnection(connection:IEventDispatcher):void
		{
			if(connection)
			{
				connection.removeEventListener(ConnectionEvent.CONNECTION_CONNECTED, onConnected);
				connection.removeEventListener(ConnectionEvent.CONNECTION_CONNECT_FAIL, onConnectFail);
				connection.removeEventListener(ConnectionEvent.CONNECTION_CONNECT_CLOSE, onConnectClose);
			}
		}
		
		
		private function setIntTo4byte(bytes:ByteArray, offset:int, value:int):ByteArray
		{
			bytes.position = offset;
			
			bytes.writeByte(value);
			bytes.writeByte(value >> 8);
			bytes.writeByte(value >> 16);
			bytes.writeByte(value >> 24);	
			return bytes;
		}
		
		private function getByteToInt(bytes:ByteArray):int
		{
			bytes.position = 0;				
			var sun:int = bytes.readUnsignedByte();			
			sun += bytes.readUnsignedByte() << 8;				
			sun += bytes.readUnsignedByte() << 16;				
			sun += bytes.readUnsignedByte() << 24;
			
			return sun;
		}
		//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
		// Event
		//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
		
		private function onConnected(evt:ConnectionEvent):void
		{
			this.dispatchEvent(new ConnectionEvent(ConnectionEvent.CONNECTION_CONNECTED));
		}
		private function onConnectSecurityError(evt:ConnectionEvent):void
		{
			errorCh("socket error", "onSecurityError");
		}
		private function onConnectFail(evt:ConnectionEvent):void
		{
			errorCh("socket error", "onConnectFail");
			this.dispatchEvent(new ConnectionEvent(ConnectionEvent.CONNECTION_CONNECT_FAIL));
		}
		private function onConnectClose(evt:ConnectionEvent):void
		{
			errorCh("socket error", "onConnectClose");
			this.dispatchEvent(new ConnectionEvent(ConnectionEvent.CONNECTION_CONNECT_CLOSE));
		}
		
		private function onConnectCallBackStatusError(evt:ConnectionEvent):void
		{
			this.dispatchEvent(new ConnectionEvent(ConnectionEvent.CALL_BACK_STATUS_ERROR));
		}
		
		private function socketDataDistributionHandler(evt:SocketDataEvent):void
		{
			_reqTimer.stop();
			_waitSeconds = 0;
			var event:ConnectionEvent = new ConnectionEvent(ConnectionEvent.SOCKET_GET_DATA);
			if(evt.socketMsg.compressType == 1 )
				evt.socketMsg.dataBytes.uncompress();
			event.interacterData = evt.socketMsg;			
			this.dispatchEvent(event);
		}
		
		private function checkTimeoutHandler(evt:TimerEvent):void
		{
			this._waitSeconds++;
			if(this._waitSeconds > WAIT_TIME_OUT)
			{
				trace("socket timeout");
				errorCh("socket error", "onConnectTimeOut");
				this.dispatchEvent(new ConnectionEvent(ConnectionEvent.REQ_TIME_OUT));
				this._waitSeconds = 0;
				this._reqTimer.stop();
			}
		}
	}
}
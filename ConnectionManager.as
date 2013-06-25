package manager.connection
{
	import flash.events.EventDispatcher;
	
	import frame.command.AppNotification;
	import frame.command.BaseNotification;
	import frame.command.cmdInterface.INotification;
	import frame.utils.format.DoTimeFormat;
	
	import manager.connection.interaction.ConnectionProxy;
	
	import netWork.SocketMessage;
	import netWork.event.ConnectionEvent;
	
	import utils.console.errorCh;
	import utils.console.infoCh;
	
	/**
	 * 连接管理器 
	 * @author songdu.greg
	 * 
	 */	
	public class ConnectionManager extends EventDispatcher
	{
		private var _proxy:ConnectionProxy;
		
		private var _delegate:ConnectionManagerDelegate = null;
		
		private static var _instance:ConnectionManager = null;
//==============================================================================
// Public Functions
//==============================================================================
		public function ConnectionManager(code:$)
		{
			this._proxy = new ConnectionProxy();
			this.addListenerProxy(this._proxy);
			this._delegate = ConnectionManagerDelegate.instance;
			this._delegate.init(this);
		}	
		
		public static function get instance():ConnectionManager
		{
			return _instance ||= new ConnectionManager(new $);
		}
		
		/**
		 * 是否已经连接
		 * @return	Boolean	连接成功
		 */
		public function get connected():Boolean
		{
			return this._proxy.connected;
		}
		
		public function get delegate():ConnectionManagerDelegate
		{
			return this._delegate;
		}
		
		/**
		 * 开始连接, 只有在使用socket通讯时才有作用
		 * @param	host	String	主机地址
		 * @param	port	int		端口
		 */
		public function socketConnection(host:String, port:int):void
		{
			errorCh("socket 连接请求", "请求连接");
			this._proxy.socketConnect(host, port);
		}
		
		public function createNote(commandType:String):AppNotification
		{
			var notification:INotification = new BaseNotification();
			var note:AppNotification = new AppNotification(commandType, notification);
			return note;
		}
		
		public function send(data:Object):void
		{
			errorCh("socket 发送数据 connected", "发送数据请求" + connected);
			if (connected)
				_proxy.sendProtoBufData(data);
		}
		
		public function closeConnect():void
		{
			_proxy.close();
		}
//------------------------------------------------------------------------------
// Private
//------------------------------------------------------------------------------
		private function addListenerProxy(proxy:ConnectionProxy):void
		{
			proxy.addEventListener(ConnectionEvent.CONNECTION_CONNECTED, connectedHandler);
			proxy.addEventListener(ConnectionEvent.CONNECTION_CONNECT_FAIL, connectFailHandler);
			proxy.addEventListener(ConnectionEvent.CONNECTION_CONNECT_CLOSE, connectionCloseHandler);
			proxy.addEventListener(ConnectionEvent.REQ_TIME_OUT, connectionTimeOutHandler);
			
			proxy.addEventListener(ConnectionEvent.CALL_BACK_STATUS_ERROR, connectionCallBackErrorHandler);
			proxy.addEventListener(ConnectionEvent.SOCKET_GET_DATA, socketGetDataHandler);
		}
		
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Event
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
		private function connectedHandler(evt:ConnectionEvent):void
		{
			infoCh("Socket状态", "已连接"+ DoTimeFormat.digitalTime(new Date().getUTCSeconds()));
			this._delegate.responseConnected(true);
		}
		
		private function connectFailHandler(evt:ConnectionEvent):void
		{
			infoCh("Socket状态", "连接失败");
			this._delegate.responseConnected(false);
		}
		
		private function connectionCloseHandler(evt:ConnectionEvent):void
		{
			errorCh("time:" + DoTimeFormat.digitalTime(new Date().getUTCSeconds()));
			infoCh("Socket状态", "连接断开");
			this._delegate.responseConnected(false);
		}
		
		private function connectionTimeOutHandler(evt:ConnectionEvent):void
		{
			infoCh("Socket状态", "连接超时");
			this._delegate.connectTimeOut();
		}
		
		private function connectionCallBackErrorHandler(evt:ConnectionEvent):void
		{
			this._delegate.connectCallBackError();
		}
		
		
		private function socketGetDataHandler(evt:ConnectionEvent):void
		{
			try
			{
				this._delegate.distributionSocketMsg(evt.interacterData as SocketMessage);
			}
			catch(error:Error)
			{
				
			}
		}
	}
}

class ${}
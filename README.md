# api 网关程序

镜像名称 ： docker.hnjing.com:5000/xxx/xxxx

当前版本 : 1.2.8

## 依赖的后端服务

服务名称 | 描述
---- | ----
xx_v1 | 登录/登出/验证功能
xx_v1 | 用户信息及权限

## 配置

修改 docker 的环境变量来配置运行参数

环境变量名称 | 默认值 | 描述 | 类型
----| ---- | ---- | ---
EXPIRE | 7200秒  | token 过期时长 | 数字
REDIS_HOST | 无（需要配置环境变量）  | redis 主机 | IP 或 hostname
REDIS_PORT | 6379 | redis 端口 | 数字
NGINX_ENV | production | 运行环境变量 | 字符串,取值范围 ( development 、 production ), 如是 development 环境，将开启 lua_code_cache off 状态
PROXY | 无 | 依赖的后端口服务 | 后端口服务名 如: us_v1?body_size=10m,os_v1?real=192.168.1.2:8080
STATIC_FILE | 无 | 配置多个静态文件访问路径 | J例如：url=/xx/check/&path=/static_xxx_check/|url=/auth/&path=/staticfile/ url： 访问路径 path : 静态文件存放目录
AUTH | 无 | 认证验证 | 如: AUTH=zyx 使用智平台验证方式, include, token=token_name&allow_cookie&allow_header&allow_url
API_STATISTICS | 无 | 统计openapi接口调用 | 如: xxx_v1=192.168.135.48

### AUTH （std 通用） 参数

> 配置环境变量 AUTH=std ，表示使用规范网关认证方式， 使用方式： AUTH=std|参数1=值1,参数2=值2

参数名称 | 默认值 | 描述 | 类型 | 是否可为空
---- | ---- | ---- | --- | ---
login_url | xx_v1@/xx/v1/gateway/login | 后端登录地址 | 字符串 | 是
api_url | xx_v1@/xx/v1/gateway/apis | 后端查询权限、灰、白接口地址 | 字符串 | 是
permission_url | xx_v1@/os/v1/gateway/permission | 后端查询用户接口权限的地址 | 字符串 | 是
key | xxx | 认证集合标识(用于代表一套认证体系的关键词, 如: xxx 或 xx 或 xxx 等) | 字符串 | 否
include | 无 | 需要认证的服务名称( 值格式如 xxx_v1,xx_v1) | 字符串 | 是

#### 通用网关接口调用及返回值约定

##### login_url

登录接口 服务名称 + /gateway/login  POST 方法，

##### api_url

获取权限接口 服务名称 + /gateway/permission?auth=1&appName=%s GET 方法，按应用名称和接口类型返回接口
参数:
  auth: 1 为权限接口 2 为白名单接口 3 为灰名单接口
  appName: 表示为应用名称，如 crm / qiye 等
返回值类似如下:

```json
[
 {
   "apiId": 1,                  // 接口id
   "method": "get",             // 方法名称
   "apiDivisor": "/os/v1/xxx"   // 接口地址
 },
 ...
]
```

##### permission_url

获取用户权限接口 服务名称 + /gateway/user/%s/apis GET 方法，根据 userId 返回用户的接口权限id列表

返回值类似如下:

```json
[
 1,2
]
```

SERVICES 参数

参数名称 | 描述
---- | ----
real | 真实代理主机地址， 如: us_v1?real=192.168.150.40 , 转换 nginx 配置为 proxy_pass http://192.168.150.40/us/v1
path | 后端口服务地址，如果没有，就以默认规则 如 us_v1 解析为 proxy_pass http://us_v1/us/v1
location | 代理地址 ，默认为服务名，如： us_v1 代理的地址为 /us/v1/
auth | 是否需需要权限验证, 取值范围 true/false ， 默认为 true

跳过接口权限验证方法 （开发环境适用）

> 为方便开发人员调用接口，减少生成权限的次数，特加了跳过接口权限验证的方法，如果需要，请在请求头中添加 no-auth 头，值为需要跳过权限证验的服务名列表，格式如： no-auth: os,us

网关返回错误代码及描述, 格式如下：

```json
 {
   "code": 401001,
   "message": "找不到身份验证信息"
 }
```

> 如果是网关抛出的错误，会在响应头部加入 flag: gateway

 HTTP 状态码 | 错误代码 | 描述
 ---- | ---- | ----
 400 | 400001 | 请求的地址不正确，可能原因： 没有使用 host 标记调用后端接口或没有使用 xxx.cn 主域名访问接口
 400 | 400002 | 缺少登录信息 （ 登录 ）
 400 | 400003 | 缺少认证信息 （ 登录 ）
 400 | 400004 | 无效的认证信息或认证信息已过期 （刷新 token）
 401 | 401001 | 请求后端接口没有带上 token (身份验证信息)
 401 | 401002 | 请求后端接口带入的 token 无效或已过期
 401 | 401003 | 用户已在其它地方登录
 401 | 401004 | 用户的权限或密码被修改，需要重新登录
 401 | 401005 | 找不到相关用户，用户被禁用或被删除
 403 | 403001 | 对接口没有访问权限
 500 | 500001 | 无法解析 redis 主机
 500 | 500002 | 连接不到 redis 数据库
 500 | 500003 | 查找 redis 数据时， 查询 key 时失败
 500 | 500004 | 查找 redis 数据时， 无法找到相关的 key
 500 | 500005 | 将权限因子 path 参数转换为正则表时失败 (转义)
 500 | 500006 | 将权限因子 path 参数转换为正则表时失败（替换 {} 内容为正则）
 500 | 500007 | 没有定义 info 的字典共享数据 请在 nginx.conf 中定义 info 字典
 500 | 500008 | 没有配置获取所有权限因子接口地址， 环境变量： API_GET_ALL_PERMISSIONS 环境变量
 500 | 500009 | 向 info 字典中写入权限信息失败
 500 | 500010 | 向 info 字典中写无验证（白名单）接口列表时失败
 500 | 500011 | 向 info 字典中写无验证（灰名单）接口列表时失败
 500 | 500012 | 转换获取用户信息 url 地址错误
 500 | 500013 | 无法解析上游服务器主机地址
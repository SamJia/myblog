---
title: 通过Webhook实现Sentry错误自动化飞书机器人报警
tags: Sentry webhook fastapi
---

Sentry可以收集程序的各类异常消息，为了更好地实时报警，期望通过飞书机器人自动在监控群内报警。

<!--more-->

---

## 飞书机器人

飞书中，可以在任意群聊添加自定义机器人，之后只需要向该机器人的webhook地址发送特定post请求，即可通过该机器人向群内发送消息。

![飞书机器人](/blog/assets/images/2022-05-20-sentry-webhook/feishu_robot.png){:.border.zoom}


## sentry webhook报警

sentry的各个项目均可配置警报信息，在`project`->`setting`->`alert`中，可以添加WEBHOOKS报警。
但是由于sentry向该webhook发送的数据格式和飞书机器人需要的数据格式不一致，因此我们还需要做一个web服务，来支持数据格式转换，并发送自定义格式的飞书消息。



## webhook API

此处通过`python`的`fastapi`框架实现该API：

```python
import json
import datetime

from fastapi import FastAPI, Query, Body


app = FastAPI(
    docs_url='/api/v1/docs',
    redoc_url='/api/v1/redoc',
    openapi_url='/api/v1/openapi.json'
)

@app.post('/hook', status_code=201)
async def sentry_hook(
        feishu: str = Query('https://open.feishu.cn/open-apis/bot/v2/hook/xxxxxxxxx'),
        data=Body(...),
):

    level = data['level'].upper()
    color = {
        'ERROR': 'red',
        'WARNING': 'yellow',
        'INFO': 'blue',
    }.get(data['level'], 'red')
    project_name = data['project']
    env = data['event'].get('environment', 'UNKNOWN')
    timestamp = datetime.datetime.fromtimestamp(data['event']['timestamp'])
    issue_id = data['id']
    error_type = data['event']['metadata'].get('type', '')
    exception_title = data['culprit']
    exception_value = data['event']['metadata'].get('value', '')
    message = data['message']
    issue_url = data['url']
    parsed_uri = urlparse(issue_url)
    sentry_url = f'{parsed_uri.scheme}://{parsed_uri.netloc}/'

    data = {
        'msg_type': 'interactive',
        'card': {
            'config': {
                'wide_screen_mode': True,
                'enable_forward': True,
            },
            'header': {
                'template': color,
                'title': {
                    'content': f'【网站服务{level}】 {project_name}项目在{env}环境出现异常',
                    'tag': 'plain_text'
                }
            },
            'elements': [
                {
                    'fields': [
                        {
                            'is_short': True,
                            'text': {
                                'content': f'**🕐 时间：**\n{timestamp.strftime("%Y-%m-%d %H:%M:%S")}',
                                'tag': 'lark_md'
                            }
                        },
                        {
                            'is_short': True,
                            'text': {
                                'content': f'**📋 项目：**\n{project_name}',
                                'tag': 'lark_md'
                            }
                        },
                        {
                            'is_short': False,
                            'text': {
                                'content': '',
                                'tag': 'lark_md'
                            }
                        },
                        {
                            'is_short': True,
                            'text': {
                                'content': f'**📍 部署环境：**\n{env}',
                                'tag': 'lark_md'
                            }
                        },
                        {
                            'is_short': True,
                            'text': {
                                'content': f'**🔢 事件 ID：**\n{issue_id}',
                                'tag': 'lark_md'
                            }
                        },
                        {
                            'is_short': False,
                            'text': {
                                'content': '',
                                'tag': 'lark_md'
                            }
                        },
                    ],
                    'tag': 'div'
                },
                {
                    'tag': 'div',
                    'text': {
                        'content': f'**{error_type} {exception_title}**\n{exception_value}\n\n**Message: **\n{message}',
                        'tag': 'lark_md'
                    }
                },
                {
                    'actions': [
                        {
                            'tag': 'button',
                            'text': {
                                'content': '开始处理',
                                'tag': 'plain_text'
                            },
                            'type': 'primary',
                            'url': issue_url,
                            'value': {
                                'key': 'value'
                            }
                        }
                    ],
                    'tag': 'action'
                },
                {
                    'tag': 'hr'
                },
                {
                    'elements': [
                        {
                            'content': f'[来自Sentry日志平台]({sentry_url})',
                            'tag': 'lark_md'
                        }
                    ],
                    'tag': 'note'
                }
            ]
        }
    }

    headers = {
        'Content-Type': 'application/json',
    }

    requests.post(feishu, headers=headers, data=json.dumps(data, ensure_ascii=False).encode('utf-8'))
```

## sentry 报警配置

配置sentry中一个项目的报警规则主要有两部分，第一是在`project`->`setting`->`alert`中添加wenhook链接：

![sentry webhook设置](/blog/assets/images/2022-05-20-sentry-webhook/sentry_webhook.png){:.border.zoom}

之后还需要设置报警触发规则，在`Alert`管理页面，创建针对该项目的`Alert Rule`。
如下图，该设置表示当出现一个新的报错，或者是之前被标记为`ignored`或者`resolved`的报错重新出现时，会通过该项目的WEBHOOKS配置进行报警，且同一个issue60分钟内只会报警1次，避免短时间过多报警信息轰炸。

![sentry alert rule设置](/blog/assets/images/2022-05-20-sentry-webhook/alert_rule.png){:.border.zoom}

配置成功后，当项目内出现新的报错信息时，飞书机器人则会发送如下图所示的消息卡片，点击`立即处理`按钮即可跳转至sentry中该issue页面，查看详细信息并处理。

![报错信息卡片](/blog/assets/images/2022-05-20-sentry-webhook/error_message.png){:.border.zoom}

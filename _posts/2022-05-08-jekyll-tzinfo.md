---
title: Jekyll和tzinfo-2.0不兼容导致时区识别失败
tags: Jekyll  ruby  tzinfo
---

在Windows平台下，由于时区问题，导致使用Jekyll加载最新的一些blog时出现错误：

Skipping: _drafts/2022-05-08-nas-iftop.md has a future date
{:.error}

<!--more-->

---

## 问题描述

如上报错表明这个blog由于带有未来的日期，因此被jekyll跳过（不过该功能可能可以帮助实现天级别的定时发布，虽然可能要定时重新编译，比较麻烦）。

正常来说，通过jekyll设置时区是在`_config.yml`文件中设置变量`timezone`，如`timezone=Asia/Shanghai`，这种设置下时区应当是`UTC+8`。

而如果jekyll未能正确识别该时区，使用默认的`UTC-0`，则会落后8个小时，若北京时间在0点-8点之间，则会导致jekyll认为还在上一天，因此无法加载最新写的blog。

## 解决方案

### 暴力方案

既然jekyll默认会跳过未来日期的blog，那如果更改该设置，使其不跳过，则可避免该问题。

在`_config.yml`中添加`future: true`配置则可实现。

添加后，重启jekyll服务，则可发现全部blog均可被识别，不论日期如何。

但是该方法治标不治本，jekyll实际使用的时区仍然是错的，仍有潜在风险。

### 正确识别时区

jekyll识别时区错误主要是因为`tzinfo`这个gem的版本问题。

根据jekyll[官方文档](https://www.jekyll.com.cn/docs/installation/windows/)，Windows平台下jekyll和`TZInfo 2.0`不兼容。

> 基于19年时的一个[issue](https://github.com/jekyll/jekyll/issues/7565)，当时未尝试适配`TZInfo 2.0`主要是因为其依赖的库`activesupport`依赖于`v1.x`的tzinfo。
>
> 但是在2022年5月测试，`activesupport`库已经适配tzinfo-2.0。不知未来jekyll合适跟进，适配`v2.x`。

因此如果要解决这个问题，则需要安装`v1.x`版本的`tzinfo`，通过在`Gemfile`内添加

```text
gem 'tzinfo', '~> 1.2.0'
```

如果之前已经安装过其他相关依赖，由于`activesupport`最新版本已经要求安装`v2.x`的`tzinfo`，因此直接安装依赖会产生冲突报错。

此时删除`Gemfile.lock`文件和`vendor`目录，之后重新执行依赖安装命令即可：

```shell
bundle install
```

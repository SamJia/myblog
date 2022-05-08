---
title: Jekyll框架中图片缩放功能
tags: Jekyll  fancybox js
---

Jekyll的博客模板中虽然可以添加图片，但是图片无法缩放交互，导致有些细节看不清楚。

<!--more-->

---

## fancybox

为了能够支持图片的缩放等高级功能，需要使用相关js库。本文选择使用`fancybox@v4.0`

该库包含一个js文件和一个css文件，均可从其[官网](https://fancyapps.com/docs/ui/installation#cdn)下载或从cdn导入。

根据其[文档](https://fancyapps.com/docs/ui/quick-start#declarative)，对需要缩放的元素增加`data-fancybox`属性，并设置data-src或者href指向原始素材链接，则可自动实现对相关素材的缩放功能：

```html
<a
  href="https://lipsum.app/id/1/1024x768"
  data-fancybox="gallery"
  data-caption="Optional caption"
>
  Image
</a>
```

为了能够让全局可以导入fancybox，则可在框架的`head.html`等设置全局head标签内容的文件中添加对fancybox库的引入，本文设置在`/_includes/head/custom.html`这一框架预留的自定义头文件中。

```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@fancyapps/ui@4.0/dist/fancybox.css?v=4.0.26" >
<script src="https://cdn.jsdelivr.net/npm/@fancyapps/ui@4.0/dist/fancybox.umd.js?v=4.0.26"></script>
```

## markdown应用

在jekyll中，可以通过如下方式撰写markdown：

```markdown
![image-title](/path/to/image.jpg){:class="zoom" data-fancybox="demo" style="cursor: zoom-in;"}
```

其生成的html为：

```html
<img alt="image-title" src="url" class="zoom" data-fancybox="demo" style="cursor: zoom-in;">
```

则此时鼠标悬停于该图片时可以出现放大镜图标，同时点击后则可以看到缩放后的效果，就如下图所示：

![缩放示例](/blog/assets/images/2022-05-08-jekyll-image-zoom/zoom_example.png){: data-fancybox="demo" style="cursor: zoom-in;"}


## fancybox自动化高级设置

在需要缩放的img中添加对应属性已经可以实现缩放效果，但是仍有两方面缺点：

+ 每个图片都需要设置大量的属性，较为繁琐
+ 此时只能使用fancybox的默认设置，功能较为简陋

因此考虑在全局添加js代码，自动为img添加属性，并设置更多fancybox的高级选项。具体来说，在`/_includes/head/custom.html`文件中，继续添加如下代码：

```html
<script src="{{ _sources.jquery }}"></script>
<script>
  // 自动添加图片属性
  $(document).ready(function() {
    $(".zoom").attr('data-fancybox', 'gallary').css('cursor', 'zoom-in');
  });

  // 设置缩放样式
  Fancybox.bind('[data-fancybox="gallary"]', {
  Image: {
    zoom: true,
    Panzoom: {
      zoomFriction: 0.7,
      maxScale: function () {
        return 5;
      },
    },
  },
  showClass: "fancybox-zoomIn",
  hideClass: "fancybox-zoomOut",
});
</script>
```

首先引入jquery库，之后选择所有带有`zoom`class的元素，设置相关属性，之后再调用`Fancybox.bind`函数绑定所需选项。

此时只需要在需要缩放的图片添加一个`zoom`class，即可实现预设好的图片缩放功能。如添加img：

```markdown
![image-title](/path/to/image.jpg){:.zoom}
```

则可实现如下效果：

![缩放示例2](/blog/assets/images/2022-05-08-jekyll-image-zoom/zoom_example.png){:.border.zoom}

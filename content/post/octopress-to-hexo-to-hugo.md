+++
date = "2015-12-10T18:17:49-05:00"
title = "Octopress to Hexo to Hugo"
description = "Why this blog is now using Hugo"
tags = [
  "hugo"
]
draft = false
+++
This blog post is really just to say **"Wow! Hugo is freakin' awesome!"**

## <a href="http://octopress.org/">Octopress</a>

![Octopress](/img/octopress.png)

Octopress definitely got the job done and introduced me to static blog generators, but I had no real desire to learn Ruby and lately with Windows 10, I've booted up to Linux less and less (yes, Windows 10 really is pretty good - if only it had a bash terminal).  Installing Ruby on Windows just wasn't something I wanted to bother with.  Also, if I wanted to change the underlying templates, it just seemed more complicated than it really needed to be and I couldn't find the time or motivation to really bother changing the default template much.

<br/>
## <a href="https://hexo.io/">Hexo</a>

![Hexo](/img/hexo.png)

Soooooooo... the next logical step seemed to be Hexo.  NodeJS - easy enough on Windows and I've done a little node development here and there so here we go.  Somehow this just seemed a bit kludgy too.  It's a decent enough project, but just didn't quite feel right.

<br/>
## <a href="https://gohugo.io/">Hugo</a>

![Hugo](/img/hugo.jpg)

I've been looking for excuses to learn Go, so on a whim, googled static blog generators and Go.  I'm yet to really learn any Go from using Hugo (other than perusing the code), but still it's nice to know it's there if I need to dig through source to figure out what's up or want to dive deeper and contribute to the project.

At any rate, Hugo *just feels right.*  Not only was I able to migrate my existing blog fairly quickly, but it was not only easy, but also *fun* to start hacking on an existing theme.

Reasons I love Hugo:  

- Installation is just a matter of adding a .exe to your PATH and your good to go.  Can't argue with that.
- Good documentation - was fairly easy to get started (one hint though: you need to specify a theme or it will seem like it's failing silently)
- Go templates seem mostly straightforward and powerful
- **SPEED** - this wasn't really a criteria for me since this blog is pretty small but with Hugo's speed (100ms to generate this blog) along with its **built-in live reload**, development is easy and fun.

This blog is currently running off a moderately modified <a href="https://github.com/digitalcraftsman/hugo-steam-theme">Steam</a> theme.  Development is fun enough that hopefully it will continue to evolve (in other words, I don't feel like I'm *fighting the framework* with Hugo).

I also found these resources especially helpful for migration:  

- http://nathanleclaire.com/blog/2014/12/22/migrating-to-hugo-from-octopress/
- https://gohugo.io/tutorials/github-pages-blog/

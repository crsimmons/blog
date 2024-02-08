---
layout: post
title:  "Yubikey All The Things"
date:   2023-11-09
categories: EB yubikeys
---
A guide on how to use [Yubikey USB security devices][yubi] for the following purposes:

* [Stores and loads our personal SSH keys][ssh]
* [Provides one-touch two-factor authentication][2fa]
* [Stores and recalls our 1Password secret keys][static]
* [Allows Git commits to be signed, proving the author's identity][signing]

## SSH

After a little setup, an engineer inserts their Yubikey, enters a PIN, and then their SSH key is loaded all the time the device is connected. By generating the RSA key on the device, it never exists on disk anywhere else.

[Yubikeys for SSH][ssh]

## 2FA

Having to use one's phone every few minutes to enter a 2FA code for the myriad services we use is a pain. Yubikeys support U2F, which makes 2FA as simple as pressing the button on your Yubikey device. With the help of a Yubico app, you can also use it for old-school time-based one-time-passwords.

[Yubikeys for 2FA][2fa]

## Static secrets

The Yubikey can be configured to type in a string when its button is long-pressed. This is a great way to get your (very long, very hard to remember) 1Password secret key when using a shared machine. This means you only have to remember your email address and password to access your password vault, but with all the benefits of an extra secret for higher entropy.

[Yubikeys for static secrets][static]

## Commit signing

You can use the GPG key created on the Yubikey to sign your Git commits, meaning that you can prove that you really are the author of commits with your name on, and that no-one is masquerading as you.

[Yubikeys for signed Git commits][signing]

> Originally posted in 2017 by a former colleague [Paddy Steed][paddy]
{: .prompt-info }

[2fa]: /posts/yubikey-2fa/
[paddy]: https://www.linkedin.com/in/paddy-steed/
[signing]: /posts/yubikey-signed-commits/
[ssh]: /posts/yubikey-ssh/
[static]: /posts/yubikey-static-secret/
[yubi]: https://www.yubico.com/products/yubikey-5-overview/

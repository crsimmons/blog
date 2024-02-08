---
layout: post
title:  "Yubikeys for SSH Auth"
date:   2023-11-09
categories: EB yubikeys
---
You can use a Yubikey USB device to securely _generate_ and store your SSH key. This can be used to load your private key on demand, protected by a PIN. Perfect for pair-programming on shared machines!

> This post is part of [a series on using Yubikeys][yubi-home] to secure development whilst pair-programming on shared machines.
{: .prompt-info }

In this post I will show you how to use your Yubikey to generate and store an RSA key, and then configure your computer to use GPG to load that key and authenticate with remote SSH servers. Each time you authenticate you'll need to have your Yubikey inserted, and you'll be prompted for a PIN.

I'll assume you have a [Yubikey][yubi]. Some of the terminal output will differ slightly depending on your operating system; these snippets are captured on Fedora.

## Why store your RSA key on a Yubikey?

Digital security is generally much more difficult than physical security.
If I have a secret written on a piece of paper, I could hide that paper somewhere, I could keep it on my person, I could put it in safety deposit box.
All of these are pretty good ways to make sure nobody reads whatever is on the paper, and all are simple to reason about.
If I have that same secret on a file on my laptop, however, there is much more to think about.
Every piece of software I run has permission to read that file.

My laptop has a network connection, so an attacker does not need to ever meet me to steal my secret.
A Yubikey _almost_ turns a digital security problem into a physical security one.

If your SSH key is stored on a Yubikey it cannot be copied, it cannot be stolen remotely, and the software on whatever machine you stick it into cannot read it.
You can even PIN protect the key, which means that if somebody physically steals your Yubikey they would have to guess the PIN correctly to be able to use it, and even then, they would be unable to extract the key.

> On 15 October 2017 a serious problem was announced in a library used by Yubikey firmware responsible for generating RSA keys. The [ROCA (Revenge of Coppersmith's Attack)][roca] hack enables the computing of the private part of a RSA keypair from the public part alone. This **is fixed in all Yubikeys manufactured since June 2017**.
{: .prompt-warning }

## Set Yubikey PINs

**Install `gpg` using your operating system's package manager** so that you can interact with your Yubikey.

> `gpg 2.2.23` has a bug that prevents on-card key generation. Despite what's written in the bug report, we've had success with version `2.2.22`.
{: .prompt-warning }
> `gpg 2.3` and above enables `CCID` (Chip Card Interface Device) by default.  You may want to disable this to make it compatible with older Yubikeys.  To do this, you'll need to edit `~/.gnupg/scdaemon.conf` (it may need creating) and add the line `disable-ccid`.
{: .prompt-info }

Plug in your Yubikey, and run `gpg --change-pin` to change the PIN from the default of `123456`. This is the PIN you'll be asked to enter whenever you need to access the private key, for example when doing `git push`.

Despite the term PIN, it can be **up to 8 alphanumeric characters**.

```terminal
$ gpg --change-pin
1 - change PIN
2 - unblock PIN
3 - change Admin PIN
4 - set the Reset Code
Q - quit
Your selection? 1
Please enter the PIN
New PIN
New PIN
PIN changed.
```

If you enter your newly-set PIN incorrectly three times then the Yubikey will be locked, and you must unlock it using the admin PIN, which is `12345678` by default.

You should change the admin PIN too, by running the same command again, this time selecting option 3:

```terminal
$ gpg --change-pin
1 - change PIN
2 - unblock PIN
3 - change Admin PIN
4 - set the Reset Code
Q - quit
Your selection? 3
gpg: 3 Admin PIN attempts remaining before card is permanently locked
Please enter the Admin PIN
New Admin PIN
New Admin PIN
Admin PIN changed.
```

If you later enter the admin PIN incorrectly three times you will need to factory-reset the Yubikey.

## Configure Machines to use GPG Agent

Firstly, you need to configure `ssh` on the machines you'll be working on to use `gpg-agent` to handle authentication, which will in turn load an RSA key from your Yubikey - provided that you enter the correct PIN.

The below snippet appends the appropriate config to your `.bashrc` (if you use zsh you will need to append these lines to `~/.zshrc` instead).

```terminal
$ cat <<EOF >> ~/.bashrc
export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye
unset SSH_AGENT_PID
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
EOF
$ . ~/.bashrc
```

## Install a PIN entry GUI

You may also want to install a GUI for entering your Yubikey's PIN.

The default `pinentry-curses` CLI tool always uses the `tty` it was started in, which gets problematic when changing terminals or when PIN entry was prompted by a background process (such as Git Radar, which we use at EngineerBetter).

To install a PIN entry GUI on **macOS**, run `brew install pinentry-mac`. On Linux you might want to install `pinentry-gui`.

`pinentry-mac` **may have additional installation steps**, so you should pay attention to the `brew install` output. At the time of writing, you are asked to configure `gpg-agent` to use `pinentry-mac` by default:

```terminal
echo "pinentry-program /usr/local/bin/pinentry-mac" >> ~/.gnupg/gpg-agent.conf
```

![pinentry-mac](/assets/img/blog/yubikey/pinentry-mac.png)

**You _may_ need to restart your machine for all changes to take effect.**

## Generate an RSA key on your Yubikey

I recommend [generating your RSA key on the Yubikey itself][roca], rather than generating the key on your computer and then copying it to the Yubikey. This way you know that it has never been on the filesystem, where it could be snooped upon.

```terminal
$ gpg --card-edit
gpg: detected reader `Yubico Yubikey 4 OTP+U2F+CCID 00 00'
Application ID ...: D2760001240102010006069174660000
Version ..........: 2.1
Manufacturer .....: unknown
Serial number ....: 06917466
Name of cardholder: [not set]
Language prefs ...: [not set]
Sex ..............: unspecified
URL of public key : [not set]
Login data .......: [not set]
Private DO 1 .....: [not set]
Private DO 2 .....: [not set]
Signature PIN ....: not forced
Key attributes ...: 2048R 2048R 2048R
Max. PIN lengths .: 127 127 127
PIN retry counter : 3 0 3
Signature counter : 0
Signature key ....: [none]
Encryption key....: [none]
Authentication key: [none]
General key info..: [none]
gpg/card> admin
Admin commands are allowed
gpg/card> generate
```

You will be asked if you want to backup the encryption key.
If you are only using this key for SSH authentication I would recommend you do not do this.
It is fairly easy to go though this process again if you lose your Yubikey, and it means your key will never leave your Yubikey.

```terminal
Make off-card backup of encryption key? (Y/n) n
Please note that the factory settings of the PINs are
   PIN = `123456'     Admin PIN = `12345678'
You should change them using the command --change-pin
gpg: gpg-agent is not available in this session
Please enter the PIN
What keysize do you want for the Signature key? (2048)
What keysize do you want for the Encryption key? (2048)
What keysize do you want for the Authentication key? (2048)
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
```

By default, your key will not expire. I would recommend setting an expiry date.

```terminal
Key is valid for? (0) 1y
Key expires at Wed 14 Nov 2018 14:18:02 GMT
Is this correct? (y/N) y
You need a user ID to identify your key; the software constructs the user ID
from the Real Name, Comment and Email Address in this form:
    "Heinrich Heine (Der Dichter) <heinrichh@duesseldorf.de>"
Real name: Paddy Steed
Email address: paddy.steed@engineerbetter.com
Comment:
You selected this USER-ID:
    "Paddy Steed <paddy.steed@engineerbetter.com>"
Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? O
gpg: generating new key
gpg: 3 Admin PIN attempts remaining before card is permanently locked
Please enter the Admin PIN
gpg: please wait while key is being generated ...
gpg: key generation completed (4 seconds)
gpg: signatures created so far: 0
gpg: generating new key
gpg: please wait while key is being generated ...
gpg: key generation completed (6 seconds)
gpg: signatures created so far: 1
gpg: signatures created so far: 2
gpg: generating new key
gpg: please wait while key is being generated ...
gpg: key generation completed (9 seconds)
gpg: signatures created so far: 3
gpg: signatures created so far: 4
gpg: key A4D581D2 marked as ultimately trusted
public and secret key created and signed.
gpg: checking the trustdb
gpg: public key of ultimately trusted key 53157188 not found
gpg: 3 marginal(s) needed, 1 complete(s) needed, PGP trust model
gpg: depth: 0  valid:   2  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 2u
gpg: next trustdb check due at 2018-11-14
pub   2048R/A4D581D2 2017-11-14 [expires: 2018-11-14]
      Key fingerprint = 31A1 BADF 181F B053 0D06  8B45 7B4E 9486 A4D5 81D2
uid                  Paddy Steed <paddy.steed@engineerbetter.com>
sub   2048R/0A3CA35A 2017-11-14 [expires: 2018-11-14]
sub   2048R/4746682A 2017-11-14 [expires: 2018-11-14]
gpg/card> quit
```

Your RSA key is now generated, and the public key is stored on your GPG keychain.

## Sharing your public key

The public key that you generated is stored in your local keychain (eg `~/.gnupg/pubring.kbx`). However, we need to share it with the world for two reasons:

1. In order to [be able to sign commits][yubi-commits] on other machines, those machines will need a copy of your public key.
1. The fact that your public key is, well, _public_, makes it easier to trust - the longer something has been in the public domain and relied upon, the less likely it is to be forged or inauthentic.

You should upload your public key to one or more popular keyservers:

```terminal
$ gpg --list-secret paddy.steed@engineerbetter.com
sec>  rsa2048 2017-11-22 [SC] [expires: 2021-04-29]
      FEEDBEEFC0C0A7D867D34ADEADD0D0CAFEDECADE
      Card serial no. = 0006 06917459
uid           [ unknown] Paddy Steed <paddy.steed@engineerbetter.com>
ssb>  rsa2048 2017-11-22 [A] [expires: 2021-04-29]
ssb>  rsa2048 2017-11-22 [E] [expires: 2021-04-29]
```

**Copy the long ID** from the output above, and then upload it to one or more servers:

```terminal
gpg --keyserver keys.openpgp.org     --send-key FEEDBEEFC0C0A7D867D34ADEADD0D0CAFEDECADE
gpg --keyserver keys.gnupg.net       --send-key FEEDBEEFC0C0A7D867D34ADEADD0D0CAFEDECADE
gpg --keyserver pgp.mit.edu          --send-key FEEDBEEFC0C0A7D867D34ADEADD0D0CAFEDECADE
gpg --keyserver keyserver.ubuntu.com --send-key FEEDBEEFC0C0A7D867D34ADEADD0D0CAFEDECADE
```

**If** you experience the following error `gpg: keyserver send failed: Server indicated a failure`,  try adding the `hkp` protocol along with a port override:

```terminal
gpg --keyserver hkp://keys.gnupg.net:80 --send-key FEEDBEEFC0C0A7D867D34ADEADD0D0CAFEDECADE
```

Now the public key is safely stored elsewhere, you can get back to configuring SSH.

## Viewing the public key

Assuming you have configured `gpg-agent` correctly. `ssh-add -L` will display the public key in SSH format (you may need to open a new shell session if your ssh-agent already has a key loaded).

```terminal
$ ssh-add -L
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCy7PhCvbb+R0UIsQdBvIpWQNSBOZkfV+7E0d55Gxzppt9tvQHbWJwzi/… cardno:000606917466
```

You can put this in `~/.authorized_keys` for any machine you want to be able to log in to, and paste it into GitHub, GitLab, and similar tools.

## In action

1. Start a terminal, or `source ~/.bashrc` if you're using the same terminal as earlier
1. Open a git repository with a remote that uses an ssh URI
1. Do a `git pull`, and see that authentication fail (you shouldn't have any keys loaded at this point - you can list loaded keys with `ssh-add -l`)
1. Insert your Yubikey
1. Do a `git pull`
1. Observe the PIN entry GUI
1. Enter your PIN
1. Observe the GUI disappear, and the `git pull` complete successfully.
1. Remove your Yubikey when you're done working on that machine.

## Extending an expired GPG key

Earlier in this post it was recommended that your GPG key was given an expiry date. What happens when it expires?

If your GPG key has expired, assuming that [you've configured Git to use it for commit signing][yubi-commits], you'll see this when trying to commit:

```terminal
error: gpg failed to sign the data
fatal: failed to write commit object
```

You can extend the life of your key simply.

Ensure that your Yubikey is inserted, and run `gpg --list-secret <your-email-address>`. This will show the key and subkeys:

```terminal
gpg: checking the trustdb
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
gpg: next trustdb check due at 2023-04-29
sec>  rsa2048 2017-11-22 [SC] [expires: 2023-04-29]
      FEEDBEEFC0C0A7D867D34ADEADD0D0CAFEDECADE
      Card serial no. = 0006 06917459
uid           [ultimate] Daniel Jones <daniel.jones@engineerbetter.com>
ssb>  rsa2048 2017-11-22 [E] [expires: 2023-04-29]
ssb>  rsa2048 2017-11-22 [A] [expires: 2023-04-29]
```

Enter the interactive GPG key-editing prompt with `gpg --edit-key <long-id-from-above>`, and you'll see something like this:

```terminal
sec  rsa2048/ADD0D0CAFEDECADE
     created: 2017-11-22  expires: 2023-04-29  usage: SC
     card-no: 0006 06917459
     trust: ultimate      validity: ultimate
ssb  rsa2048/BA53B2D6734C8A8E
     created: 2017-11-22  expires: 2023-04-29  usage: E
     card-no: 0006 06917459
ssb  rsa2048/AF5A4B5AA8A8C5BF
     created: 2017-11-22  expires: 2023-04-29  usage: A
     card-no: 0006 06917459
[ultimate] (1). Daniel Jones <daniel.jones@engineerbetter.com>
```

By default there is no subkey selected, so we'll be operating on the main key. Use the `expire` command, and you'll be prompted to enter a number followed by a unit, such as `2y` for two years. Upon pressing `return`, you'll be prompted to verify the expiration date, which you should confirm.

```terminal
gpg> expire
Are you sure you want to change the expiration time for multiple subkeys? (y/N) y
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0) 2y
Key expires at Sat 29 Apr 12:17:52 2023 BST
Is this correct? (y/N) y
```

You'll then get this hint:

```terminal
gpg: WARNING: Your encryption subkey expires soon.
gpg: You may want to change its expiration date too.
```

We now need to select the subkeys for editing too. They are 1-indexed, and are selected with the `key N` command. Each selected key will have an asterisk next to it. `key 0` will deselect subkeys.

```terminal
gpg> key 1

sec  rsa2048/ADD0D0CAFEDECADE
     created: 2017-11-22  expires: 2023-04-29  usage: SC
     card-no: 0006 06917459
     trust: ultimate      validity: ultimate
ssb* rsa2048/BA53B2D6734C8A8E
     created: 2017-11-22  expired: 2021-04-29  usage: E
     card-no: 0006 06917459
ssb  rsa2048/AF5A4B5AA8A8C5BF
     created: 2017-11-22  expired: 2021-04-29  usage: A
     card-no: 0006 06917459
[ultimate] (1). Daniel Jones <daniel.jones@engineerbetter.com>
```

Select all subkeys, and then run the `expire` command exactly as you did for the main key. Your keys are now extended, and you may now commit as normal.

> Originally posted in 2017 by a former colleague [Paddy Steed][paddy]
{: .prompt-info }

[paddy]: https://www.linkedin.com/in/paddy-steed/
[roca]: https://www.yubico.com/support/security-advisories/ysa-2017-01/
[yubi-commits]: /blog/yubikey-signed-commits
[yubi-home]: /posts/yubikey-all-the-things
[yubi]: https://www.yubico.com/products/yubikey-5-overview/

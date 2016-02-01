# Setting Up


## Install Virtualbox

Make sure you have Virtualbox installed on your device

## Install Vagrant

Use your OS's package manager or go to Vagrant website to download and install
Vagrant.

## Install Vagrant VB Guest

This will make sure your Guest OS is synced with Virtualbox server's version

> $ vagrant plugin install vagrant-vbguest

## Create new folder 'src/' in this repo clone folder

## Drop source code in main project directory

These projects should be placed in `src/` directory of this project

- sellercenter (Ember source code)
- moxy (API and Magazine source code)
- moxy-indonesia (Moxy's Magento source code)
- bilna-magento (Bilna's Magento source code)
- bilna-django (Bilna's Django source code)

## Setting up Hosts

Setup the following hosts to access your projects:

```
10.0.0.10   moxy.local
10.0.0.10   api.moxy.local
10.0.0.10   sellercenter.moxy.local
10.0.0.10   bilna.local
10.0.0.10   magazine.bilna.local
10.0.0.10   api.bilna.local
10.0.0.10   sellercenter.bilna.local
```

## Important!
## You need ubuntu image file and database dump data before you can run vagrant, ask someone for help :D

## Run Vagrant

> $ vagrant up


## After vagrant has setup your server:

### Open moxy magento

```
http://moxy.local/
```

### Open moxy magento admin page

```
http://moxy.local/admin/
user: admin   pass: admin12345
```

### Open moxy magazine

```
http://moxy.local/magazine/
```

### Open moxy magazine admin page

```
http://moxy.local/magazine/admin/
user: admin   pass: default
```

### Open moxy seller center

```
http://sellercenter.moxy.local/
```

### Open moxy seller center admin

```
http://api.moxy.local/admin/
user: admin   pass: default
```

### Open bilna magento

```
http://bilna.local/
```

### Open bilna magento admin page

```
http://bilna.local/admin/
user: taufik  pass: admin12345
```

### Open phpmyadmin

```
http://moxy.local/phpmyadmin/
user: root    pass: Dev2016
```

## Other vagrant commands

### Login to server

> $ vagrant ssh

### Shutting down

> $ vagrant halt

### Suspend

> $ vagrant suspend

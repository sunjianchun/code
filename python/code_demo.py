
#1： Django自定义login的demo
@csrf_exempt
def my_login(request):
        if request.method == 'GET':
                return HttpResponse("<form method=\"post\">姓名：<input type=\"text\" name=\"username\" id=\"username\"><br/>密码：<input type=\"password\" id=\"password\" name=\"password\"><input type=\"submit\" value=\"submit\"></form>")
        else:
                username = request.POST['username']
                password = request.POST['password']
                print username, password
                user = authenticate(request, username=username, password=password)
                if user is not None:
                        login(request, user)
                        return HttpResponse('login ok')
                else:
                        return HttpResponse('login error')

#2: 获得文件内容的md5               
def md5_file(fname):
    hash_md5 = hashlib.md5()

    with open(fname, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
        return hash_md5.hexdigest()

import os, sys

template = open('header_template.html').read()

filenames = [f for f in os.listdir('.')
    if f != 'header_template.html' and f.endswith('.html')]


for filename in filenames:
    name_dir = {}
    for name in filenames:
        if name == filename:
            name_dir[os.path.splitext(os.path.basename(name))[0]] = 'navcur'
        else:
            name_dir[os.path.splitext(os.path.basename(name))[0]] = 'nav'
    file = open(filename).read()
    nav = {'nav': template % name_dir}
    new_file = open(os.path.join('..', 'html_doc', filename), 'w')
    new_file.write(file % nav)
    new_file.close()

from asyncio.windows_events import NULL
from base64 import encode
from datetime import datetime
import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
import os 

options = webdriver.EdgeOptions()
options.add_experimental_option("debuggerAddress", "127.0.0.1:9222")
driver = webdriver.Edge( options=options)

file_list = os.listdir("dockerfile")
for item in file_list:
    uri = "dockerfile\\"+item
    tmp_list = os.listdir(uri)
    if len(tmp_list) == 0:
        driver.get("https://github.com/search?o=desc&q="+item+"&s=stars&type=Repositories")
        dockerfile = driver.find_element_by_xpath('/html/body/div[5]/main/div[1]/div[3]/div[1]/ul[1]/li[1]/div[2]/div[1]/div[1]/a')
        time.sleep(0.8)
        repo = dockerfile.text
        origin = driver.current_window_handle
        href = "https://github.com/search?q=&type=Code"
        driver.execute_script(f'window.open("{href}");')
        driver.switch_to.window(driver.window_handles[-1])
        text = driver.find_element_by_name("q")
        text.send_keys("repo:"+repo+" language:Dockerfile")
        submit = driver.find_element_by_xpath('/html/body/div[5]/main/div[1]/div[1]/form/div/button')
        submit.click()
        time.sleep(1)
        code = driver.find_element_by_xpath('/html/body/div[5]/main/div[1]/div[2]/nav[1]/a[2]')
        code.click()
        time.sleep(1.5)
        dockerfiles = driver.find_elements_by_xpath('/html/body/div[5]/main/div[2]/div[3]/div[1]/div[2]/div[1]/div')

        second_window = driver.current_window_handle
        for k in range(len(dockerfiles)):
            print(k)
            dockerfile = driver.find_element_by_xpath('/html/body/div[5]/main/div[2]/div[3]/div[1]/div[2]/div[1]/div['+str(k+1)+']/div[1]/div[2]/a')
            href = dockerfile.get_attribute('href')
            print(href)
            driver.execute_script(f'window.open("{href}");')
            driver.switch_to.window(driver.window_handles[-1])
            time.sleep(1)
            #raw = driver.find_element_by_xpath('/html/body/div[5]/div[1]/main/div[2]/div[1]/div[1]/div[4]/div[1]/div[2]/div[1]/a[1]')
            raw = driver.find_element_by_link_text("Raw")
            raw.click()
            time.sleep(1)
            dockerfile_raw = driver.find_element_by_xpath('html/body/pre')
            text = dockerfile_raw.text
            out_file = open("dockerfile\\"+item+"\\"+str(k)+".dockerfile","w+",encoding="utf-8")
            print(text,file=out_file)
            out_file.close()
            driver.close()
            driver.switch_to.window(second_window)
        driver.close()
        driver.switch_to.window(origin)

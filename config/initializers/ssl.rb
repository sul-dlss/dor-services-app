# By default Ruby 2.5 tries to use SSLv23.
# This sometimes causes this error:
#   OpenSSL::SSL::SSLError: SSL_connect returned=1 errno=0 state=SSLv2/v3 read server hello A
#
# See: https://stackoverflow.com/questions/9175151/connecting-using-https-to-a-server-with-a-certificate-signed-by-a-ca-i-created/9262269#9262269

OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ssl_version] = 'TLSv1_2'

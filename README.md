# Sitefull::Oauth

This is a gem for authenticating and authorizing against different cloud providers that support OAuth 2.0.
 
[![Build
Status](https://travis-ci.org/stanchino/sitefull-oauth.svg?branch=master)](https://travis-ci.org/stanchino/sitefull-oauth)
[![Code
Climate](https://codeclimate.com/github/stanchino/sitefull-oauth/badges/gpa.svg)](https://codeclimate.com/github/stanchino/sitefull-oauth)
[![Test
Coverage](https://codeclimate.com/github/stanchino/sitefull-oauth/badges/coverage.svg)](https://codeclimate.com/github/stanchino/sitefull-oauth/coverage)
[![Issue
Count](https://codeclimate.com/github/stanchino/sitefull-oauth/badges/issue_count.svg)](https://codeclimate.com/github/stanchino/sitefull-oauth)
[![Dependency
Status](https://www.versioneye.com/user/projects/56d4d0b40a4ec126f7f86088/badge.svg?style=flat)](https://www.versioneye.com/user/projects/56d4d0b40a4ec126f7f86088)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sitefull-oauth'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sitefull-oauth

## Usage

### Amazon
  * Setup a new application for Login with Amazon [https://sellercentral.amazon.com/gp/homepage.html](https://sellercentral.amazon.com/gp/homepage.html)
  * Create am IAM role in the AWS Management Console to allow the users access to your resources:
    * Login to the AWS Management Console [https://console.aws.amazon.com/iam/home#home](https://console.aws.amazon.com/iam/home#home)
    * Go to the [Roles](https://console.aws.amazon.com/iam/home#roles) section and click on "Create New Role"
    * Choose "Role for Identity Provider Access" on the "Select Role Type" page and select the "Grant access to web identity providers" option
    * Select "Login with Amazon" and entery your Application ID for the application you created
    * Follow the wizard and create the new role
    * Edit the new role and from the "Permissions" tab select policies that the authenticated users will be able to access

Once the Amazon application is configured and the role is setup you can use the [Sitefull Oauth](https://github.com/stanchino/sitefull-oauth) gem to generate credentials for the Amazon SDK for Ruby [https://aws.amazon.com/sdk-for-ruby/](https://aws.amazon.com/sdk-for-ruby/)
  * Configure the provider class:
```
options = {
  client_id: "Amazon Application Client ID",
  client_secret: "Amazon Application Client Secret",
  role_arn: "IAM Role ARN",
  redirect_uri: "One of the Allowed Return URLs for the Amazon Application"
}
provider = Sitefull::Oauth::Provider.new('amazon', options) ;
```
  * Generate the authorization URL and open it in a web browser
```
provider.authorization_url
```
  * Get the authorization code from the URL and request an access token
```
provider.authorize!('The code from the URL parameters when you are redirected to the redirect_uri')
```
  * Generate credentials for the AWS SDK for Ruby [https://aws.amazon.com/sdk-for-ruby/](https://aws.amazon.com/sdk-for-ruby/)
```
credentials = provider.credentials
```
  * Add the credentials to the AWS API client:
```
client = Aws::EC2::Client.new(region: 'us-east-1', credentials: credentials)
client.describe_instances
```

### Azure
  * Setup a new application in Active Directory following the steps described here [https://azure.microsoft.com/en-us/documentation/articles/active-directory-integrating-applications/](https://azure.microsoft.com/en-us/documentation/articles/active-directory-integrating-applications/)

Once the application is configured you can use the [Sitefull Oauth](https://github.com/stanchino/sitefull-oauth) gem to generate credentials for the Microsoft Azure SDK for Ruby [https://github.com/Azure/azure-sdk-for-ruby](https://github.com/Azure/azure-sdk-for-ruby)
  * Configure the provider class:
```
options = {
  tenant_id: "Your Azure Application Tenant ID",
  client_id: "Azure Application Client ID",
  client_secret: "Azure Application Client Secret",
  redirect_uri: "One of the Reply URLs for the Azure Application"
}
provider = Sitefull::Oauth::Provider.new('azure', options) ;
```
  * Generate the authorization URL and open it in a web browser
```
provider.authorization_url
```
  * Get the authorization code from the URL and request an access token
```
provider.authorize!('The code from the URL parameters when you are redirected to the redirect_uri')
```
  * Generate credentials for the Azure SDK for Ruby [https://github.com/      Azure/azure-sdk-for-ruby](https://github.com/Azure/azure-sdk-for-ruby)
```
credentials = provider.credentials
```
  * Add the credentials to one of the the Azure API client libraries ([Compute](resource_management/azure_mgmt_compute), [Network](resource_management/azure_mgmt_network), [Storage](resource_management/azure_mgmt_storage) or [Resources](resource_management/azure_mgmt_resources)):
```
client = Azure::ARM::Resources::ResourceManagementClient.new(credentials)
```
**NOTE** You will need to set the client subscription ID before you can query the Azure APIs:
```
client.subscription_id = 'The desired subscription ID'
client.resources.list.value!
```

### Google
  * Setup a new OAuth client ID in the Google developer console [https://console.developers.google.com/apis/credentials](https://console.developers.google.com/apis/credentials)

Once the OAuth application is configured you can use the [Sitefull Oauth](https://github.com/stanchino/sitefull-oauth) gem to generate credentials for the Google API Client [https://github.com/google/google-api-ruby-client](https://github.com/google/google-api-ruby-client)
  * Configure the provider class:
```
options = {
  client_id: "Google OAuth Client ID",
  client_secret: "Google OAuth Client Secret",
  redirect_uri: "One of the Authorized redirect URIs"
}
provider = Sitefull::Oauth::Provider.new('google', options) ;
```
  * Generate the authorization URL and open it in a web browser
```
provider.authorization_url
```
  * Get the authorization code from the URL and request an access token
```
provider.authorize!('The code from the URL parameters when you are redirected to the redirect_uri')
```
  * Generate credentials for the Google API Client [https://github.com/google/google-api-ruby-client](https://github.com/google/google-api-ruby-client)
```
credentials = provider.credentials
```
  * Add the credentials to the Google API client you want to use
```
require 'google/apis/compute_v1'
client = Google::Apis::ComputeV1.new
client.authorization = credentials
client.list_images('A project the authenticated user can access')
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/stanchino/sitefull-oauth. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


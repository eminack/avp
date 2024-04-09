# Gem Readme v4

---

The gem is a wrapper on the Amazon Verified Permissions Service ( [AVPS](https://www.notion.so/Readme-bc17263574d245598ad9543152989672?pvs=21) ), which is hosted solution for authorization system based on cedar policy language.

## WHAT IS IT FOR ?

This gem allows you to model an authorization system. It allows to answer authorization decisions such as

1. Does user:123 has permission to access a company:123 ?
2. Does Organization O has show access to Filter F ?

Bascially anything which is an authorization can be modelled by the system

> Mathematically, it allows to model permissions and answer queries described below.

PERMISSIONS MODELLED:
**Allow/Forbid a group/single `ACTION` `A` on a group/single `RESOURCE` `R` by a group/single `PRINCIPAL` `P`**

QUERIES ANSWERED
**Does `PRINCIPAL P` has access to `ACTION` `A` on `RESOURCE` `R` ?**
>

### **Response Time**

It does all this in ***< 10 Ms*** Latency

---

## **SUPPORTED MODELS**

1. **RBAC ( Role based Access Control)**[Link](https://www.permit.io/blog/cedar-rbac)
2. **RBAC with resource roles**: define roles that receive a set of permissions granted by associating policies with the role. These roles can then be assigned to one or more identities. Each assigned identity acquires the permissions granted by the policies associated with the role.
3. **ABAC ( Attribute based Access Control)**[Link](https://aws.amazon.com/blogs/security/how-we-designed-cedar-to-be-intuitive-to-use-fast-and-safe/): attributes attached to the principal and the resource to determine the permissions. Syntax sugar like resource.Owner can be used to get the attribute for a resource.
4. **Deny-override**: both allow and deny authorizations are supported, deny overrides the allow.
5. Default deny, forbid wins, no ordering
6. **VPS Data Model**: Cedar’s data model, which organizes entities into a hierarchy. Entities correspond to objects within your application, such as photos and users. The hierarchy reflects grouping of entities, such as nesting of photos into albums.

   ![68747470733a2f2f6432393038713031766f6d7162322e636c6f756466726f6e742e6e65742f323264323030663836373064626462336532353361393065656535303938343737633935633233642f323032332f30382f31382f696d67322d312e6a7067.jpeg](https://prod-files-secure.s3.us-west-2.amazonaws.com/8958e5ed-aa2b-4c03-8809-1a07595ffc6d/4107e2f0-401f-4226-9d90-0a463ca6a1a6/68747470733a2f2f6432393038713031766f6d7162322e636c6f756466726f6e742e6e65742f323264323030663836373064626462336532353361393065656535303938343737633935633233642f323032332f30382f31382f696d67322d312e6a7067.jpeg)


## FEATURES

1. Enforce the policies in the classic `{ principal, action, resource }` form.
2. Handles the storage of access control model and it's policies.
3. Define resources, actions, principals using a schema. Strong validation support for creating policies.
4. Multiple built in operators to support the rule matching. For eg: `like` to match regexes ,`in` to check presence in groups & hierarchies` [Link](https://docs.cedarpolicy.com/syntax-operators.html)

### **HOW TO USE ?**

1. **Configure your credentials by creating** `avp.rb` **file**

   Create an initializer in `config/initializers/avp.rb`

    ```ruby
    AVP.configure do |config|
    	config.default_store = 'xxx'
    	config.default_scope = 'labs_core'
    end
    ```


1. include `AVP::Principal` module in your **class which can act as an actor.**


    Eg : We have a **UserEntity** class which has multiple properties namely `id, uuid, name, email, organization`
    
```ruby
   class UserEntity
      include AVP::Principal
      
      # name: provide a string which uniquely identifies this model 
      # parents: are used to define hierarchy 
      # identifier: provide a string which uniquely identifier an instance of this object
      
      # avp_configuration name: 'User', parents: [:organization], identifier: :uuid
      
      avp_configuration name: 'User', parents: [{key: 'organization', class: 'OrganizationEntity'}], identifier: :uuid
    
      
      const :uuid, String 
      const :organization, OrganizationEntity 
      # has multiple other attributes
   end 
```
    
```ruby
class OrganizationEntity   
  include AVP::Principal
  avp_configuration name: 'Organization', identifier: :uuid
    
  const :uuid, String
  # has multiple other attributes
end
```


1. include `AVP::Resource` module in classes which act as resource. Eg `ListEntity` here acts as a resource for VPS

```ruby 
  class ListEntity
    include AVP::Resource
    	
    	# define method name as symbols
    avp_configuration name: 'List', actions: [:get_list,:update_list,:delete_list], identifier: :id
    	
    const :id, Integer # has multiple other attributes
    
  end
```


### **Creating Policy Templates**

Create policies folder at component level, inside that define multiple files each denoting a policy.  Before deploy each policy template will be synced with upstream AWS VPS

![Untitled Diagram.drawio (3).png](https://prod-files-secure.s3.us-west-2.amazonaws.com/8958e5ed-aa2b-4c03-8809-1a07595ffc6d/e7425010-c287-4b34-94f8-a167a4533c57/Untitled_Diagram.drawio_(3).png)

```ruby
class ListOwnerPolicy
	include AVP::PolicyTemplate

	# define a name and description of the policy
	name 'list_owner_policy'
	description 'This policy allows principal to have CRUD actions permitted on List resource'
	belongs_to ListEntity
	
	allow (
		# define actions which are allowed
		actions: [:update_list, :get_list, :delete_list]
		
		# resource act as placeholder
		resource: {}

		# allow nesting in principals
		principal: { nested: true }
	)

end
```

```ruby
class ListViewerPolicy
	include AVP::PolicyTemplate
	
	name 'list_viewer_policy'
	description 'This policy allows principal to have Get action permitted on List resource'
	
	allow(
		actions: [:get_list]
		resource: {}
		principal: { nested: true}
	)
end
```

### C**hecking authorization**

```ruby
# you can directly query from Principal entities, based on actions defined in resource class

UserEntity.new(...).can_get_list?(ListEntity.new(...)) -> Boolean

UserEntity.new(...).can_delete_list?(ListEntity.new(...))

```

### **Assigning Policies**

```ruby
UserEntity.new(...).policies.assign(policy_name: 'owner_list_policy', resource: ListEntity.new(..._))
```

### **Filtering Policies**

```ruby
# Filter out policies based on policy_name, principal, resource attached to policies

policies = ListEntity.new(...).policies.list(name: 'owner_list_policy')

# Filter out policies on principal as well
policies = UserEntity.new(...).policies.list(resource: ListEntity.new(...))

```

### **Deleting Policies**

```ruby
# You can call delete on policy object returned from list API
ListEntity.new(...).policies.list(...).map(&:delete)
```

### **Feature Permissions**

Create feature classes which can act as resource for feature

Eg: Modelling CRM feature permission here

```ruby
module CRM
  module Features 
    class Company 
      include AVP::Resource
      
      avp_configuration scope: 'LabsCore::CRM', name: 'Company', identifier: 'crm_company'
                        actions: [:create_company,:bulk_create_company, :sync_company] 
    end 
  end
end
```

**Checking Authorization**

```ruby
user.can_bulk_create_company?(CRM::Features::Company.new)
```

---

### **Creating Static Policies**

create classes in policies directory at component level, each file defines template/static policies. Before deploy each static policy will be synced upstram with AWS VPS.

```ruby
class ListDeletePermission
	include AVP::StaticPolicy

	name 'owner_delete_policy'
	description 'This policy allows only owner of list to delete a list'
	belongs_to ListEntity

	allow {
		actions: [:delete_list]
	}
	
	condition {
		when: 'resource.owner_type = principal.type &&	resource.owner_id = principal.id'
	}

end
```

### **Discussion Points**

1. **Checking Authorization**

```ruby
1st case
user.can_bulk_create_company?(CRM::Features::Company.new) 

VS 

2nd case
CRM::Features::Company.new.is_bulk_create_company_allowed?(user)
```

***In 1st case*** :

`bulk_create_company?` action can be defined on `N` no of resource. So you must know what resource is passed to know exactly whats going on

***In 2nd case:***

We are querying from resource end, reading from left to right makes sense

<aside>
💡 Note: Above differenciation is  more prevelant in Features case . In other cases mostly both way will make equal sense

</aside>

### **Examples**

[List Modelling](list_example.md)

---

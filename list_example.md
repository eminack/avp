# List Modelling

**Requirements** -

1. Owners of list can crud in list
2. subscribers of list can only get the list
3. List owned by organization - users can not delete that list but can view,update all of them,
4. System type of lists are visible across all orgs, but no one can modify it ( their owner are of type AdminUser)

### **Setting up avp.rb**

```ruby
Avp.configure do |config|
	config.default_store = 'dbsad88787bsbnxsadas'
	config.default_scope = 'RailsBackendServer'
end
```

### **Define resources, principals**

**Defining Principals**

include AVP::Principal in `User, Organization, AdminUser` classes. Define scope, type, attribute serializers

```ruby
# typed: strict

module SynapticUser
  module Entity
    class User < T::Struct
      extend T::Sig
      include AVP::Principal
			
      avp_configuration name: 'User', attribute_serializer: SynapticUser::AVPAttributeSerializer,
                        parents: [{key: 'organization', class_name: 'SynapticUser::Entity::Organization'}], 
                        identifier: -> (object) { object.id.to_s }

      const :id, Integer
    end
  end
end
```

```ruby
# typed: strict

module SynapticUser
  module Entity
    class Organization < T::Struct
      extend T::Sig
      include AVP::Principal
      
      avp_configuration name: 'Organization', attribute_serialize: SynapticUser::AVPOrgAttributeSerializer, 
                        identifier: -> (object) { object.id.to_s }

      const :id, Integer
    end
  end
end
```

```ruby
class AdminUser < ApplicationRecord 
  include AVP::Principal
  
  avp_configuration name: 'AdminUser', attribute_serializer: AdminUser::AVPAttributeSerializer, 
                    identifier: -> (object) { object.id.to_s }
end
```

```ruby
# typed: strict

module SynapticList
  module Entity
    class List < T::Struct
      extend T::Sig
      include AVP::Resource
      
      avp_configuration name: 'List', attribute_serializer: SynapticList::AVPAttributeSerializer, 
                        actions: [:deleteList, :updateList, :getList], identifier: ->(object) { object.id.to_s }

      const :id, T.nilable(Integer)
    end
  end
end
```

### **Defining Attribute Serializers**

```ruby
module SynapticUser
  class AVPAttributeSerializer < ::AVP::AttributeSchemaSerializer

    columns([{ key: 'type', type: 'String' },{key: 'id', type: 'String'}])

    def type
      "User"
    end

    def id
      object.id.to_s
    end
  end
end

module SynapticUser 
  class AVPOrgAttributeSerializer < ::AVP::AttributeSchemaSerializer 
    columns([{ key: 'type', type: 'String' },{key: 'id', type: 'String'}])    
    
    def type
      "Organization"
    end    
    
    def id 
      object.id.to_s 
    end 
  end
end

module SynapticList
  class AVPAttributeSerializer < AVP::AttributeSchemaSerializer
    columns([{ key: 'owner_type', type: 'String' },{key: 'owner_id', type: 'String'},{key: 'list_type', type: 'String'}])

    def list_type
      object.list_type.serialize
    end

    def owner_id
      object.owner_id.to_s
    end

    def owner_type
      object.owner_type.serialize
    end
  end
end
```

### **Create Policies**

1. **create templates**

   This policy allows `Get, update, delete` operation to a specified `prinicpal and resource`

    ```ruby
    module SynapticList
      class ListOwnerTemplate
        include AVP::PolicyTemplate
    
        description 'This policy allows principal to have RUD actions permitted on List resource'
       
        name 'list_owner_policy'
        belongs_to SynapticList::Entity::List
        allow(
          actions: [:get_list, :update_list, :delete_list],
          resource: {},
          principal: { nested: true }
        )
      end
    end
    ```

   This policy allows `Get` operation to a specified `prinicpal and resource`

    ```ruby
    module SynapticList
      class ListViewerTemplate
        include AVP::PolicyTemplate
    
        description 'This policy allows principal to have Get action permitted on List resource'
        name 'list_viewer_policy'
        belongs_to SynapticList::Entity::List
        allow(
          actions: [:get_list] ,
          resource: {},
          principal: { nested: true }
        )
    
      end
    end
    ```


1. **Create Static Policies**

   This policy restrict only owners of list to delete the list

  ```ruby
  module List   
    module Policies
      class OwnerDeletePolicy
        include AVP::StaticPolicy
            
        avp_name 'list_owner_delete_policy'
        avp_description 'This policy restricts to delete list only by owner of list'
      
        belongs_to SynapticList::Entity::List
        
        forbid (
           actions: [:delete_list]
        )
        condition: (
          unless: 'resource.owner_type = principal.type &&	resource.owner_id = principal.id '
        )
      end
    end
  end
  ```

This policy allows system lists to be visible to all users accross all orgs

```ruby
    module SynapticList
      class SystemListPolicy
        include AVP::StaticPolicy
    
        description 'This policy allows system lists to be visible to all users'
        name 'system_list_view_policy'
        belongs_to SynapticList::Entity::List
        
        allow(
          actions: [:get_list]
        )
        condition(
          when: " resource.list_type == \"system\" "
        )
      end
    end
```


## Application FLow

### List Creation & Sharing

**Suppose a list is created by “aman” and shared with “satyam”**

```ruby
list = ::List.create(owner: 'Aman',....)

# assign owner role to User 'Aman'
User.find('Aman').policies.assign(policy_name: 'list_owner_policy', resource: list)

# assign viewer role to User 'Satyam'
User.find('Satyam').policies.assign(policy_name: 'list_viewer_policy', resource: list)
```

### Checking List Access Permission: Case 1

`Check if “sameer”  belonging to organiztion “nvst” has getList action allowed on List with id “10” ?`

```ruby

# directly user action names defined in resource file ( here list.rb) as method names
is_authorized = User.find('sameer').can_get_list?(List.find('10')) 

# OUTPUT - false : because list is owned by aman and only shared with satyam hence sameer cannot perform getList on list:10
```

### **List Reshared with Others**

Now List:10 is shared with whole org instead of 1 user

```ruby
list = ::List.find(10)

# filter out policies which have viewer role attached to this list, # delete all above policies
policies = list.policies.list(policy_name: 'list_viewer_policy').map(&:delete)

# assign viewer role to whole organization
Organization.find('nvst').assign(policy_name: 'list_viewer_policy', resource: list)
```

### Checking List Access Permission: Case 2

`Now we need to check if “satyam” belonging to organizaiton “nvst” has  ”getList” action permission on List with id 10`

```ruby

# directly user action names defined in resource file ( here list.rb) as method names
is_authorized = User.find('satyam').can_get_list?(List.find('10')) 

# OUTPUT - Allowed, because list is owned by aman and shared with whole organization
```

### **New List created with Organization as Owner**

Now suppose a new list is created and it’s owner is `organization:nvst`. Since it is owned by organizations so it has no explicit viewer policy attached to it

```ruby
list = List.create(owner: Organization.find('nvst')....)

# assign organization list_owner_policy role
Organization.find('nvst').policies.assign(policy_name: 'list_owner_policy', resource: list)
```

### **Checking List Access Permission: Case 3**

`Now we check if User::”aman” belonging to organization “nvst” has “deleteList” action permission on List:”11” ?`

```ruby
is_authorized = User.find('aman').can_delete_list?(List.find('11')) 
# OUTPUT: false. Because of Static policy 1 above. Only owners of list are allowed to delete a list.
```

---

